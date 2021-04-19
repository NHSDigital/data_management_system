# Data Management System [![Build Status](https://github.com/publichealthengland/data_management_system/workflows/Test/badge.svg)](https://github.com/publichealthengland/data_management_system/actions?query=workflow%3Atest)

* Rails version 6.0.3.2
* Ruby version is 2.6.3

## System dependencies

  * ndr_dev_support ~> 5.7
  * ndr_error '~> 2.0'
  * ndr_support '~> 5.3'
  * ndr_ui (1.4.0)

## Configuration

Create and edit `config/database.yml` and `config/secrets.yml`

### Database creation
```
$ rails db:create
$ rails db:migrate
```
### Database initialization
```
$ rails db:seed
```
### How to run the test suite
```
$ rails db:migrate RAILS_ENV=test
$ bin/rails test
```

### Deployment instructions
Will need security credentials for server, currently : mbis_beta@ncr-prescr-app2.phe.gov.uk
Currently deployed to : https://prescriptions.phe.nhs.uk
In local repository:
```
$ bundle exec cap mbis_beta deploy:update
```
If db migrations are needed speak to db team
The restart service can be a bit flaky so best to kill main puma process then run `./start_server.sh` from `/home/mbis_front` on server

## Front End / User Guide

This web application will be used to manage how and who has access to various data extracts from ODR.

- Users must have a valid yubikey.
- Users are then created by admin users, making sure their username matches the yubikey username
- User are managed through the system except for
  1. Admin user (PHE admin staff) by adding emails into config/admin_users.yml
  2. ODR user (ODR approver) by adding emails into config/odr_users.yml
  (a user cannont belong to both)
- Users are assigned to teams.
- Teams are created and have team members, available raw data sources and projects, each team belongs to a Directorate, Division and has a Delegate User
- Projects are created from the team page
- Once project has been created and all mandatory information completed it can be submitted for ODR approval
  1. Project Details
  2. Data Items
  3. Members
  4. Uploads
- At ODR approval the ODR approver has the option to approve / reject various elements of the project
  1. Project Details
  2. Data Items
  3. Members
  4. Uploads
- If project is rejected it goes back to team to fix any problems
- If project is approved then data distribution can happen

### Notification system
The system is dependent on lots of notifications and a 'framework' is in place, however this may not be the most robust solution.
New notifications can be create with command similar to:
```ruby
Notification.create!(title: custom_title,
                      body: CONTENT_TEMPLATES['email_project_expired']['body'] %
                      { variable_1 : variable_1_value, variable_2 : variable_2_value },
                     admin_users: true/false,
                     odr_users: true/false,
                     senior_users: true/false,
                     user_id: ID,
                     projet_id: ID,
                     team_id: ID
                     all_users: true/false)
```
The Notification table is the master table for the 'notification' it uses a content template defined in config/content_templates.yml.
This template can be supplemented with given variables and the 'types' of users who should receive the message specified.
This Notification record is then used to generate individual user messages UserNotifications (after_save on Notification) so that each user can maintain a read / not read status.

### Turbolinks
Turbolinks5 has been removed from this project due to problems when using with Bootstrap (jQuery related)
To add Turbolinks:
* Add the `turbolinks` gem, version 5, to your Gemfile: `gem 'turbolinks', '~> 5.0.0'`
* Run `bundle install`
* Add `//= require turbolinks` to your JavaScript manifest file (found at `app/assets/javascripts/application.js`).

### Workflows:
Unlike other NDR projects where a workflow represents a series of discrete units of work that
occur sequentially, project workflows in MBIS are more akin to a collection of states in which a
project exists and moves between throughout its lifetime, each of which being able to
direct/control the next valid/available state(s).

Project workflows are not strictly linear; although they have states that can be considered as
the start/end of the flow, they can be somewhat cyclic in nature (e.g. the feedback loop of
submission/rejection/resubmission). It is also possible for a workflow to have multiple potential
end points.

All workflow related logic has been encapsulated within the `Workflow` module and contains the
following components:
```
  +----------------------------------------------------------------------------------------------+
  | Workflow::State               | Model   | Defines all of the potential states for projects.  |
  +----------------------------------------------------------------------------------------------+
  | Workflow::Transition          | Model   | Defines valid changes of state (i.e. for a given   |
  |                               |         | state what are the next potential states).         |
  +----------------------------------------------------------------------------------------------+
  | Workflow::ProjectState        | Model   | Essentially a ledger of what states a project has  |
  |                               |         | been in, along with the user responsible for that  |
  |                               |         | change. Should be treated as append only.          |
  +----------------------------------------------------------------------------------------------+
  | Workflow::CurrentProjectState | Model   | Provides support for accessing the current state   |
  |                               |         | of a project.                                      |
  +----------------------------------------------------------------------------------------------+
  | Workflow::Model               | Concern | Mixed into the Project model. Sets up associations |
  |                               |         | and defines the primary interface(s) for moving    |
  |                               |         | between states.                                    |
  +----------------------------------------------------------------------------------------------+
  | Workflow::Ability             | Model   | CanCan ability file describing grants relating to  |
  |                               |         | a user's permissions to make changes to project    |
  |                               |         | state. Merged into top level ability file.         |
  +----------------------------------------------------------------------------------------------+
  | Workflow::Controller          | Concern | Mixed into ProjectsController. Defines an          |
  |                               |         | endpoint/action for users to trigger changes to a  |
  |                               |         | project's state.                                   |
  +----------------------------------------------------------------------------------------------+
```

CanCan is used to control if and when an end user can make changes to a project's state.
At the highest level, a user must be authorised to perform the :transition action however this
alone is not sufficient; the user must also be able to :create the prospective
`Workflow::ProjectState` record. This gives provides a second guard to ensure that the user is
authorised to put the project into the requested state. This also allows for a relatively fine
grained control mechanism as we can judiciously apply conditions to the CanCan rules to limit
the scope of when a user may make a state change (e.g. by specifying what a project's current
state must be for user to make that change).

### Background Processing
DMS uses ActiveJob for asyncronous/background processing. This is configured to use `delayed_job`
as its backend (development/production only) and is reliant upon an additional,
external process to be started. There is a binstub for controlling this process (`bin/delayed_job`):

- Start the process in the background:
```
$ bin/delayed_job start
```
- Start the process in the foreground
```
$ bin/delayed_job run
```
- Stop the process:
```
$ bin/delayed_job stop
```
