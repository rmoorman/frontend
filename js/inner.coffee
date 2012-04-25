window.observableCount = 0

textVal = (elem, val) ->
  "Takes a jquery element and gets or sets either val() or text(), depending on what's appropriate for this element type (ie input vs button vs a, etc)"
  if elem.is("input")
    if val? then elem.val val else elem.val()
  else # button or a
    if val? then elem.text(val) else elem.text()

finishAjax = (event, attrName, buttonName) ->
  if event
    t = $(event.target)
    done = t.attr(attrName) or buttonName
    textVal t, done

    func = () =>
      textVal t, event.savedText
      t.removeClass "disabled"
    setTimeout(func, 1500)

# Make the buttons disabled when clicked
$.ajaxSetup
  contentType: "application/json"

  success: (xhr, status) ->
    finishAjax(@event, "data-success-text", "Saved")

  error: (xhr, status, errorThrown) ->
    finishAjax(@event, "data-failed-text", "Failed")

    if xhr.responseText.indexOf("<!DOCTYPE") is 0
      VM.setErrorMessage "An unknown error occurred: (#{xhr.status})."
    else
      VM.setErrorMessage "Error: #{xhr.responseText}"


  beforeSend: (xhr, status) ->
    if @event
      t = $(@.event.target)
      t.addClass "disabled"
      # change to loading text
      loading = t.attr("data-loading-text") or "..."
      @event.savedText = textVal t
      textVal t, loading





class Base
  constructor: (json, defaults={}, nonObservables=[], observe=true) ->
    for k,v of defaults
      if observe and nonObservables.indexOf(k) == -1
        @[k] = @observable(v)
      else
        @[k] = v

    for k,v of json
      if observe and nonObservables.indexOf(k) == -1
        @[k] = @observable(v)
      else
        @[k] = v

  observable: (obj) ->
    observableCount += 1
    if $.isArray obj
      ko.observableArray obj
    else
      ko.observable obj

  komp: (args...) =>
    observableCount += 1
    ko.computed args...


class HasUrl extends Base
  constructor: (json, defaults, nonObservables) ->
    super json, defaults, nonObservables

    @project_name = @komp =>
      @vcs_url().substring(19)

    @project_path = @komp =>
      "/gh/#{@project_name()}"



class ActionLog extends Base
  constructor: (json) ->
    super json, {bash_command: null, start_time: null, command: null, timedout: null, exit_code: 0, out: null, minimize: true}, ["out", "end_time", "timedout", "exit_code", "run_time_millis", "out", "start_time"]

    @status = if @end_time == null
        "running"
      else if @timedout
        "timedout"

      else if (@exit_code == null || @exit_code == 0)
        "success"
      else
        "failed"

    @success = @status == "success"

    # Expand failing actions
    @minimize(@success)


    @action_header_style = @komp =>
      css = @status

      result =
        minimize: @minimize()
        contents: @out

      result[css] = true
      result

    @action_log_style =
      minimize: @minimize()

    @start_to_end_string = "#{@start_time} to #{@end_time}"

    @duration = Circle.time.as_duration(@run_time_millis)

  toggle_minimize: =>
    @minimize(!@minimize())

  htmlEscape: (str) =>
    str.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')

  log_output: =>
    x = for o in @out
      "<span class='#{o.type}'>#{@htmlEscape(o.message)}</span>"
    x.join ""





#TODO: next step is to add the vcs_url, which is why I was looking at the knockout.model and knockout.mapping plugin
class Build extends HasUrl
  constructor: (json) ->
    # make the actionlogs observable
    json.action_logs = (new ActionLog(j) for j in json.action_logs) if json.action_logs
    super json, {}, ["build_num", "status", "committer_name", "committer_email", "why", "user", "job_name", "branch", "vcs_revision", "start_time", "build_time_millis"]


    @url = @komp =>
      "#{@project_path()}/#{@build_num}"

    @style = @komp =>
      klass = switch @status
        when "failed"
          "important"
        when "infrastructure_fail"
          "warning"
        when "timedout"
          "important"
        when "no_tests"
          "important"
        when "killed"
          "warning"
        when "fixed"
          "success"
        when "deploy"
          "success"
        when "success"
          "success"
        when "running"
          "notice"
        when "starting"
          ""
      result = {label: true, build_status: true}
      result[klass] = true
      return result


    @status_words = @komp => switch @status
      when "infrastructure_fail"
        "circle bug"
      when "timedout"
        "timed out"
      when "no_tests"
        "no tests"
      else
        @status

    @committer_mailto = @komp =>
      if @committer_email
        "mailto:#{@committer_email}"

    @why_in_words = @komp =>
      switch @why
        when "github"
          "GitHub push"
        when "trigger"
          if @user
            "#{@user} on CircleCI.com"
          else
            "CircleCI.com"
        else
          if @job_name == "deploy"
            "deploy"
          else
            "unknown"

    @pretty_start_time = @komp =>
      if @start_time
        Circle.time.as_time_since(@start_time)

    @duration = @komp () =>
      if @start_time
        Circle.time.as_duration(@build_time_millis)

    @branch_in_words = @komp =>
      return "(unknown)" unless @branch

      b = @branch
      b = b.replace(/^remotes\/origin\//, "")
      "(#{b})"



    @github_url = @komp =>
      return unless @vcs_revision
      "#{@vcs_url()}/commit/#{@vcs_revision}"

    @github_revision = @komp =>
      return unless @vcs_revision
      @vcs_revision.substring 0, 9

    @author = @komp =>
      @committer_name or @committer_email

  # TODO: CSRF protection
  retry_build: (data, event) =>
    $.ajax(
      url: "/api/v1/project/#{@project_name()}/#{@build_num}/retry"
      type: "POST"
      event: event
    )
    false

  report_build: () =>
    VM.raiseIntercomDialog('I think I found a bug in Circle at ' + window.location + '\n\n')


  description: (include_project) =>
    return unless @build_num?

    if include_project
      "#{@project_name()} ##{@build_num}"
    else
      @build_num




class Project extends HasUrl
  constructor: (json) ->
    json.latest_build = (new Build(json.latest_build)) if json.latest_build
    super json
    @edit_link = @komp () =>
      "#{@project_path()}/edit"

  @sidebarSort: (l, r) ->
    if l.latest_build()
      if r.latest_build()
        if l.latest_build().build_num < r.latest_build().build_num then 1 else -1
      else
        -1
    else
      if l.vcs_url().toLowerCase() < r.vcs_url().toLowerCase() then 1 else -1



  checkbox_title: =>
    "Add CI to #{@project_name()}"

  group: =>
    if @status() is 'available'
      "available"
    else
      "followed"

  show_enable_button: =>
    @status() is 'available'

  show_problems: =>
    @status() is 'uninferrable'

  show_options: =>
    @status() is 'followed'

  # We should show this either way, but dont have a good design for it
  show_build: =>
    @status() is 'followed'

  enable: =>
    $.post "/api/v1/project/#{@project_name()}/enable",
      (data) =>
        # Sometimes this returns {status: "available"} in development mode,
        # because the keys are already installed in production, but aren't in
        # the dev database. Solution: do nothing.
        @status(data.status)






# We use a separate class for Project and ProjectSettings because computed
# observables are calculated eagerly, and that breaks everything if the
class ProjectSettings extends HasUrl
  constructor: (json) ->
    super json

    @build_url = @komp =>
      @vcs_url() + '/build'

    @project = @komp =>
      @project_name()

    @has_settings = @komp =>
      @setup() or @dependencies() or @test() or @extra()

    @uninferrable = @komp =>
      @status() == "uninferrable"

    @inferred = @komp =>
      (not @uninferrable()) and (not @has_settings())

    @overridden = @komp =>
      (not @uninferrable()) and @has_settings()


  save_hipchat: (data, event) =>
    $.ajax(
      type: "PUT"
      event: event
      url: "/api/v1/project/#{@project_name()}/settings"
      data: JSON.stringify(
        hipchat_room: @hipchat_room()
        hipchat_api_token: @hipchat_api_token()
      )
    )
    false # dont bubble the event up

  save_specs: (data, event) =>
    $.ajax(
      type: "PUT"
      event: event
      url: "/api/v1/project/#{@project_name()}/settings"
      data: JSON.stringify(
        setup: @setup()
        dependencies: @dependencies()
        test: @test()
        extra: @extra()
      )
    )
    false # dont bubble the event up




class User extends Base
  constructor: (json) ->
    super json, {admin: false, login: "", is_new: false, environment: "production", basic_email_prefs: "all"}, [], false

    @showEnvironment = @komp =>
      @admin || (@environment is "staging") || (@environment is "development")

    @environmentColor = @komp =>
      result = {}
      result["env-" + @environment] = true
      result

  create_token: (data, event) =>
    $.ajax
      type: "POST"
      event: event
      url: "/api/v1/user/create-token"
      data: JSON.stringify {label: @label}
    false


  save_preferences: (data, event) =>
    $.ajax
      type: "PUT"
      event: event
      url: "/api/v1/user/save-preferences"
      data: JSON.stringify {basic_email_prefs: @basic_email_prefs}
    false # dont bubble the event up





display = (template, args) ->
  $('#main').html(HAML[template](args))
  ko.applyBindings(VM)

class CircleViewModel extends Base
  constructor: ->
    observableCount = 0
    @current_user = ko.observable(new User {})
    $.getJSON '/api/v1/me', (data) =>
      @current_user(new User data)

    @build = ko.observable()
    @builds = ko.observableArray()
    @projects = ko.observableArray()
    @recent_builds = ko.observableArray()
    @project_settings = ko.observable()
    @admin = ko.observable()
    @error_message = ko.observable(null)
    @first_login = true;
    observableCount += 8



  clearErrorMessage: () =>
    @error_message null

  setErrorMessage: (message) =>
    @error_message message
    $('html, body').animate({ scrollTop: 0 }, 0);


  loadProjects: () =>
    $.getJSON '/api/v1/projects', (data) =>
      start_time = Date.now()
      data = (new Project d for d in data)
      data.sort Project.sidebarSort
      @projects(data)
      window.time_taken_projects = Date.now() - start_time
      if @first_login
        @first_login = false
        setTimeout(@loadProjects, 3000)


  loadRecentBuilds: () =>
    $.getJSON '/api/v1/recent-builds', (data) =>
      start_time = Date.now()
      @recent_builds((new Build d for d in data))
      window.time_taken_recent_builds = Date.now() - start_time


  loadDashboard: (cx) =>
    @loadProjects()
    @loadRecentBuilds()
    display "dashboard", {}


  loadProject: (cx, username, project) =>
    project_name = "#{username}/#{project}"
    $.getJSON "/api/v1/project/#{project_name}", (data) =>
      start_time = Date.now()
      @builds((new Build d for d in data))
      window.time_taken_project = Date.now() - start_time
    display "project", {project: project_name}


  loadBuild: (cx, username, project, build_num) =>
    project_name = "#{username}/#{project}"
    $.getJSON "/api/v1/project/#{project_name}/#{build_num}", (data) =>
      start_time = Date.now()
      @build(new Build data)
      window.time_taken_build = Date.now() - start_time
    display "build", {project: project_name, build_num: build_num}


  loadEditPage: (cx, username, project, subpage) =>
    project_name = "#{username}/#{project}"

    # if we're already on this page, dont reload
    if (not @project_settings() or
    (@project_settings().vcs_url() isnt "https://github.com/#{project_name}"))
      $.getJSON "/api/v1/project/#{project_name}/settings", (data) =>
        @project_settings(new ProjectSettings data)

    subpage = subpage[0].replace('#', '')
    subpage = subpage || "settings"
    $('#main').html(HAML['edit']({project: project_name}))
    $('#subpage').html(HAML['edit_' + subpage]())
    ko.applyBindings(VM)


  renderAdminPage: (subpage) =>
    $('#main').html(HAML['admin']({}))
    $('#subpage').html(HAML['admin_' + subpage]())
    ko.applyBindings(VM)


  loadAdminPage: (cx, subpage) =>
    if subpage
      subpage = subpage.replace('/', '')
      $.getJSON "/api/v1/admin/#{subpage}", (data) =>
        @admin(data)
    @renderAdminPage subpage


  loadAdminProjects: (cx) =>
    $.getJSON '/api/v1/admin/projects', (data) =>
      data = (new Project d for d in data)
      @projects(data)
    @renderAdminPage "projects"


  loadAdminRecentBuilds: () =>
    $.getJSON '/api/v1/admin/recent-builds', (data) =>
      @recent_builds((new Build d for d in data))
    @renderAdminPage "recent_builds"


  loadAccountPage: (cx) =>
    display "account", {}


  loadJasmineTests: (cx) =>
    # Run the tests within the local scope, so we can use the scope chain to
    # access classes and values throughout this file.
    $.get "/assets/js/tests/inner-tests.dieter", (code) =>
      eval code

  raiseIntercomDialog: (message=null) =>
    jq = intercomJQuery
    jq("#IntercomDefaultWidget").click()
    unless jq('#IntercomNewMessageContainer').is(':visible')
      jq('.new_message').click()
    jq('#newMessageBody').focus()
    if message
      jq('#newMessageBody').text(message)

  logout: (cx) =>
    # TODO: add CSRF protection
    $.post('/logout', () =>
       window.location = "/")

  unsupportedRoute: (cx) =>
    throw("Unsupported route: " + cx.params.splat)

  filtered_projects: (filter) => @komp =>
    p for p in @projects() when p.group() == filter





window.VM = new CircleViewModel()
stripTrailingSlash = (str) =>
  str.replace(/(.+)\/$/, "$1")

$(document).ready () ->
  Sammy('#app', () ->
    @get('/tests/inner', (cx) -> VM.loadJasmineTests(cx))

    @get('/', (cx) => VM.loadDashboard(cx))
    @get('/gh/:username/:project/edit(.*)',
      (cx) -> VM.loadEditPage cx, cx.params.username, cx.params.project, cx.params.splat)
    @get('/account',
      (cx) -> VM.loadAccountPage(cx))
    @get('/gh/:username/:project/:build_num',
      (cx) -> VM.loadBuild cx, cx.params.username, cx.params.project, cx.params.build_num)
    @get('/gh/:username/:project',
      (cx) -> VM.loadProject cx, cx.params.username, cx.params.project)

    @get('/logout', (cx) -> VM.logout(cx))

    @get('/admin', (cx) -> VM.loadAdminPage cx)
    @get('/admin/users', (cx) -> VM.loadAdminPage cx, "users")
    @get('/admin/projects', (cx) -> VM.loadAdminProjects cx)
    @get('/admin/recent-builds', (cx) -> VM.loadAdminRecentBuilds cx)

    @get('(.*)', (cx) -> VM.unsupportedRoute(cx))

    # Google analytics
    @bind 'event-context-after', ->
      if window._gaq? # we dont use ga in test mode
        window._gaq.push @path

    # Airbrake
    @bind 'error', (e, data) ->
      if data? and data.error? and window.Hoptoad?
        window.Hoptoad.notify data.error

  ).run stripTrailingSlash(window.location.pathname)




# # Events
#   events:
#     "click #reset": "reset_specs"
#     "click #trigger": "trigger_build"
#     "click #trigger_inferred": "trigger_inferred_build"

#   save: (event, btn, redirect, keys) ->
#     event.preventDefault()
#     btn.button 'loading'

#     m.save {},
#       success: ->
#         btn.button 'reset'
#         window.location = redirect
#       error: ->
#         btn.button 'reset'
#         alert "Error in saving project. Please try again. If it persists, please contact Circle."

#   reset_specs: (e) ->
#     @model.set
#       "setup": ""
#       "compile": ""
#       "test": ""
#       "extra": ""
#       "dependencies": ""

#   trigger_build: (e, payload = {}) ->
#     e.preventDefault()
#     btn = $(e.currentTarget)
#     btn.button 'loading'
#     $.post @model.build_url(), payload, () ->
#       btn.button 'reset'

#   trigger_inferred_build: (e) ->
#     @trigger_build e, {inferred: true}
