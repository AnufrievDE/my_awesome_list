defmodule MyAwesomeListWeb.PageControllerTest do
  use MyAwesomeListWeb.ConnCase

  alias NaiveDateTime, as: NDT
  alias MyAwesomeList.Model.Repository, as: R
  alias MyAwesomeList.Model.Category, as: C

  @timestamp1 ~N[2010-10-10 10:10:10]
  @timestamp2 ~N[2011-11-11 11:11:11]

  @c1_params %{name: "c_test1", description: "c_desc1"}
  @c1_u_params %{name: "c_test1_u", description: "c_desc1_u"}
  @c1_u_desc %{@c1_params | description: "c_desc1_u"}

  @c2_params %{name: "c_test2", description: "c_desc2"}
  @c2_u_params %{name: "c_test2_u", description: "c_desc2_u"}
  @c2_u_desc %{@c2_params | description: "c_desc2_u"}

  @c3_params %{name: "c_test3", description: "c_desc3"}

  @r1_params %{owner: "r_test1_o", name: "r_test1", url: "r_test1_url", description: "r_desc1"}
  @r1_u_params %{@r1_params | name: "r_test1_u", description: "r_desc1_u"}
  @r1_u_desc %{@r1_params | description: "r_desc1_u"}
  @r1_add_info %{api_url: "r_test1_api_url", stargazers_count: 5, pushed_at: @timestamp1}

  @r2_params %{owner: "r_test2_o", name: "r_test2", url: "r_test2_url", description: "r_desc2"}
  @r2_u_params %{@r2_params | name: "r_test2_u", description: "r_desc2_u"}
  @r2_u_desc %{@r2_params | description: "r_desc1_u"}
  @r2_add_info %{api_url: "r_test2_api_url", stargazers_count: 10, pushed_at: @timestamp2}

  @r3_params %{owner: "r_test3_o", name: "r_test3", url: "r_test3_url", description: "r_desc3"}
  @r4_params %{owner: "r_test4_o", name: "r_test4", url: "r_test4_url", description: "r_desc4"}

  ## HTTP Status codes:
  @ok 200
  @unauthorized 401
  @forbidden 403
  @not_found 404

  test "complex CRUD test - repositories", %{conn: conn} do
    ## Create r1 and check values
    assert {:ok, r1 = @r1_params = %R{}} = R.create(@r1_params)

    ## Check that it is forbidden to create repo with the same :url
    assert {:error, %{errors: [url: {"has already been taken", _}]}} =
      R.create(%{@r2_params| url: @r1_params.url})

    ## Create r2. Check that values are set
    assert {:ok, r2 = @r2_params = %R{}} =
      R.create(Map.merge(@r2_params,
        %{inserted_at: @timestamp1, updated_at: @timestamp1}))
    ## Check that :inserted_at set manually is ignored
    assert r2.inserted_at !== @timestamp1
    ## Check that :updated_at set manually is set
    assert r2.updated_at === @timestamp1

    ## Read r1, r2 by unique fields
    assert ^r1 = R.get_by(%{id: r1.id})
    assert ^r2 = R.get_by(%{url: r2.url})
    ## There is no guarantee on db level, but it is also works:
    assert ^r1 = R.get_by(%{owner: r1.owner, name: r1.name})

    ## Update r1. Check that values are set
    assert {:ok, r1_with_info = @r1_add_info = %R{}} =
      R.update(r1, Map.merge(@r1_add_info,
        %{inserted_at: @timestamp2, updated_at: @timestamp2}))
    ## Check that inserted_at is ignored at update
    r1_with_info.inserted_at !== @timestamp2
    ## Check that updated_at is set at update
    r1_with_info.updated_at === @timestamp2

    ## Check that it is imposible to update r2.url to existing r1.url
    assert {:error, %{errors: [url: {"has already been taken", _}]}} =
      R.update(r2, %{url: r1.url})

    ## Update r2 to r3 compeletely and check values
    assert {:ok, r3 = @r3_params = %R{}} = R.update(r2, @r3_params)
    assert r2.id === r3.id

    ## Delete r3
    assert {:ok, %R{}} = R.delete(r3)
    assert nil == R.get_by(%{url: r3.url})
    assert nil == R.get_by(%{url: r2.url})

    ## Upsert r3
    assert {:ok, r3 = @r3_params = %R{}} = R.upsert(@r3_params)

    ## Update r3 to r4.params with upsert (via url)
    assert {:ok, r3u = %R{}} = R.upsert(%{@r4_params | url: r3.url})
    assert r3u.id === r3.id

    ## Update r3u with r2 additional_info with upsert (via url)
    assert {:ok, r3uu = %R{}} = R.upsert(Map.merge(@r2_add_info, %{url: r3.url}))
    assert r3uu.id === r3u.id

    resp = html_response(get(conn, "/"), @ok)
    ## Check that r1 is not displayed as it has no assoc to any category
    assert not (resp =~ r1_with_info.name)
    ## Check that there is empty list of contents
    assert resp =~ ~r/<h1>Contents<\/h1>\n<ul>\n<\/ul>/
  end

  test "complex CRUD test - categories", %{conn: conn} do
    ## Create c1 with 2 repos. Check values
    assert {:ok, c1 = @c1_params = %C{inserted_at: at,
      repositories: [c1_r1 = @r1_params = %R{}, c1_r2 = @r2_params = %R{}]}} =
        C.create(Map.merge(@c1_params, %{repositories: [@r1_params, @r2_params]}))

    ## Check :name, :description were set correctly
    #assert Map.take(c1, [:name, :description]) === Map.take(@c1_params, [:name, :description])

    ## Check that it is forbidden to create category with the same :name
    assert {:error, %{errors: [name: {"has already been taken", _}]}} =
      C.create(%{@c2_params| name: @c1_params.name})

    ## Create c2,
    ## Check that :inserted_at set manually is ignored,
    ## Check that :updated_at set manually is set,
    ## Check that other values are set
    assert {:ok, c2 = @c2_params = %C{}} =
      C.create(Map.merge(@c2_params,
        %{inserted_at: @timestamp1, updated_at: @timestamp1}))
    assert c2.inserted_at !== @timestamp1
    assert c2.updated_at === @timestamp1

    ## Read c1, c2 by unique fields
    assert ^c1 = C.get_by(%{id: c1.id})
    assert ^c2 = C.get_by(%{name: c2.name})

    ## Check that it is imposible to update c2.name to c1.name
    assert {:error, %{errors: [name: {"has already been taken", _}]}} =
      C.update(c2, %{name: @c1_params.name})

    ## Update c2. Check values
    assert {:ok, c2u_desc = @c2_u_desc = %C{}} =
      C.update(c2, Map.merge(@c2_u_desc,
        %{inserted_at: @timestamp2, updated_at: @timestamp2}))
    assert c2u_desc.id === c2.id
    ## Check that :inserted_at value is ignored at update
    assert c2u_desc.inserted_at !== @timestamp2
    ## Check that :updated_at value is set at update
    assert c2u_desc.updated_at === @timestamp2

    r1_u_with_info_params = Map.merge(@r1_u_params, @r1_add_info)
    ## Upsert c1 with new attributes.
    ## Check c1u, c1_r1u, c1_r2u values.
    assert {:ok, c1u = @c1_u_desc = %C{repositories:
      [c1_r1u = @r1_u_params = @r1_add_info = %R{},
       c1_r2u = @r2_u_params = %R{}]}} =
      C.upsert(Map.merge(@c1_u_desc,
        %{repositories: [r1_u_with_info_params, @r2_u_params]}))

    assert c1u.id === c1.id
    assert c1_r1u.id === c1_r1.id
    assert c1_r2u.id === c1_r2.id

    ## Upsert repos in c2u_desc
    assert {:ok, %C{repositories: [c2_r3 = @r3_params = %R{}]}} =
      C.upsert(Map.merge(@c2_u_desc, %{repositories: [@r3_params]}))

    resp = html_response(get(conn, "/"), @ok)
    ## Check categories toc info
    assert resp =~ c_toc_regexp(c1u)
    assert resp =~ c_toc_regexp(c2u_desc)

    ## Check categories sections info
    assert resp =~ c_section_regexp(c1u)
    assert resp =~ c_section_regexp(c2u_desc)
    ## Check repositories sections info
    assert resp =~ r_regexp(c1_r1u)
    assert resp =~ r_regexp(c1_r2u)
    assert resp =~ r_regexp(c2_r3)

    ## Check that it is unable to delete category if there are repos
    assert %Ecto.ConstraintError{constraint: "repositories_category_id_fkey"} =
      assert_raise Ecto.ConstraintError, fn -> C.delete(c2u_desc) end

    R.delete(c2_r3)
    ## Check that deletion works
    assert {:ok, %C{}} = C.delete(c2u_desc)

    ## refresh
    resp = html_response(get(conn, "/"), @ok)
    ## Check category toc info
    assert not (resp =~ c_toc_regexp(c2u_desc))
    ## Check category sections info
    assert not (resp =~ c_section_regexp(c2u_desc))
    ## Check c2_r3 repositiry sections info
    assert not (resp =~ r_regexp(c2_r3))
  end

  def c_toc_regexp(%C{name: name}), do: ~r/<a class="category-link".*#{name}<\/a>/

  def c_section_regexp(%C{name: name, description: desc}) do
    ~r"""
    <section class="category-section">.*<h2 class="category-h2">#{name}<\/h2>
    .*<div>#{desc}<\/div>
    .*<\/section>
    """s
  end

  def r_regexp(r = %R{api_url: nil}) do
    ~r"""
    <li class="category-li.*">
    .*<a href.*#{r.url}.*>#{r.name}<\/a>
    .*<span class="library-description">#{r.description}<\/span>.*<\/li>
    """s
  end
  def r_regexp(r = %R{stargazers_count: c, pushed_at: at}) do
    days_ago = MyAwesomeListWeb.PageControllerHelper.at_to_days_ago(at)
    ~r"""
    <li class="category-li.*">
    .*<a href.*#{r.url}.*>#{r.name}<\/a>
    .*<img src=\".*star.png\".*>#{c}
    .*<img src=\".*calendar.png\".*>#{days_ago}
    .*<span class="library-description">#{r.description}<\/span>.*<\/li>
    """s
  end
end
