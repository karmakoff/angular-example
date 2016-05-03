`import angular from "angular";
import $ from "jquery"`

###*
 # @ngdoc function
 # @name maxgenPromoApp.controller:CompanyContactsCtrl
 # @description
 # # CompanyContactsCtrl
 # Controller of the maxgenPromoApp
###
module.exports = [
  '$scope'
  '$state'
  '$timeout'
  'Company'
  ($scope, $state, $timeout, Company) ->
    $scope.phones = []
    $scope.wwws = []
    $scope.emails = []
    $scope.socials = [
      {
        key: 'vk'
        value: null
        parse: (url) ->
          # regexp fetches [fullUrl, protocol (http or https), vk page name, path after vk page name]
          match = url.match('^(https|http)://vk.com/([^/?]*)(.*)$') if url
          if match then match[2] else null
        validate: (value) -> value
      }
      {
        key: 'ok'
        value: null
        parse: (url) ->
          # regexp fetches [fullUrl, protocol (http or https), ok page name, path after ok page name]
          match = url.match('^(https|http)://ok.ru/([^/?]*)(.*)$') if url
          if match then match[2] else null
        validate: (value) -> value
      }
    ]

    $scope.parseSocials = () ->
      for www in $scope.wwws
        for social in $scope.socials
          social.value = social.parse www.value
          $scope.updateCompanyProperty(social) if social.value

    $scope.addWww = (isNew) ->
      id = $scope.wwws.length + 1
      key = "www_#{id}"
      value = $scope.company["www_#{id}"]
      return if not value and not isNew
      $scope.wwws.push {
        id: id
        key: key
        value: value
        validate: (url) -> url.match('^(https|http)://([a-zA-Z0-9\-.])+.([a-z])+(/.*)*$')
        valid: true
      }

    $scope.addPhone = (isNew) ->
      id = $scope.phones.length + 1
      key = "phone_#{id}"
      value = $scope.company["phone_#{id}"]
      return if not value and not isNew
      $scope.phones.push {
        id: id
        key: key
        value: value
        validate: (phone) -> phone.match /^\+\d+\s\(\d+\)\s\d\d\d\-\d\d\-\d\d$/
        valid: true
      }

    $scope.addEmail = (isNew) ->
      id = $scope.emails.length + 1
      key = "email_#{id}"
      value = $scope.company["email_#{id}"]
      return if not value and not isNew
      $scope.emails.push {
        id: id
        key: key
        value: value
        validate: (email) -> email.match /^[a-zA-Z0-9_\-\.]+@[a-zA-Z0-9_\-]+(\.){1}[a-zA-Z]+$/
        valid: true
      }

    $scope.enoughWwws = () -> $scope.wwws.length >= 3
    $scope.enoughPhones = () -> $scope.phones.length >= 3
    $scope.enoughEmails = () -> $scope.emails.length >= 3

    $scope.anyEmailEmptyOrInvalid = () ->
      (email for email in $scope.emails when not email.value or not email.valid).length
    $scope.anyPhoneEmptyOrInvalid = () ->
      (phone for phone in $scope.phones when not phone.value or not phone.valid).length
    $scope.anyWwwEmptyOrInvalid = () ->
      (www for www in $scope.wwws when not www.value or not www.valid).length

    $scope.cleanLists = () ->
      $scope.wwws = (item for item in $scope.wwws when item.value != null)
      $scope.phones = (item for item in $scope.phones when item.value != null)
      $scope.emails = (item for item in $scope.emails when item.value != null)
      $scope.addPhone()
      $scope.addPhone()
      $scope.addPhone()
      $scope.addEmail()
      $scope.addEmail()
      $scope.addEmail()
      $scope.addWww()
      $scope.addWww()
      $scope.addWww()
      $scope.addPhone(true) if $scope.phones.length == 0
      $scope.addEmail(true) if $scope.emails.length == 0
      $scope.addWww(true) if $scope.wwws.length == 0

    $scope.updateCompanyProperty = (property, allowNull) ->
      return property.valid = false if property.value and not property.validate(property.value)
      return if not allowNull and not property.value
      property.valid = true
      $scope.company[property.key] = property.value
      $scope.company.$save()

    $scope.cleanLists()

    $scope.parseSocials()

]





'use strict'

`import angular from "angular";
import register from "register";
import $ from "jquery";`

###*
 # @ngdoc service
 # @name maxgenPromoApp.ClientInfo
 # @description
 # # ClientInfo
 # Service for fetching data from company, landing, user linked and company stats
 # 
 # @method Find
 #  @param filterCompanyWhere - loopback filter.where object
 #  @returns ONE info object, see below
###

module.exports = [
  'Company'
  'User'
  'Event'
  '$q'
  'LoopbackDirect'
  (Company, User, Event, $q, LoopbackDirect) ->
    find: (filterCompanyWhere) ->
      now = new Date()
      hour = 60 * 60 * 60 * 1000
      last24Hours = new Date(now.getTime() - 24 * hour)
      last7Days = new Date(now.getTime() - 7 * 24 * hour)
      last30Days = new Date(now.getTime() - 30 * 24 * hour)
      info =
        company:
          id: null
          name: null
          registered_at: null
          activated_at: null
          admin_name: null
          admin_phone: null
          www_1: null
          last_auth_at: null
          email_for_ticket_notification: null
          address_city_1: null
          marketing_source: null
          marketing_code: null
          comment: null
          user_id: null
        user:
          email: null
        statistics:
          visitors_24_hours: null
          visitors_7_days: null
          visitors_30_days: null
          visitors_all_time: null
          tickets_24_hours: null
          tickets_7_days: null
          tickets_30_days: null
          tickets_all_time: null
          conversion_rate_24_hours: null
          conversion_rate_7_days: null
          conversion_rate_30_days: null
          conversion_rate_all_time: null
          widget_detected: null
        landing:
          promo_url: null
          disabled: null
        categories: []
        services: []

      Company.find 
        filter:
          where: filterCompanyWhere
          include: ["landings", "categories", "services"]
          fields: Object.keys(info.company)
          limit: 1
      .$promise

      .then (companies) ->
        throw 'Company not found' if companies.length == 0
        company = companies[0]
        throw 'Landing not found' if company.landings.length == 0
        info.company[key] = company[key] for key in Object.keys(info.company)
        info.landing.url_promo = company.landings[0].url_promo
        info.landing.disabled = company.landings[0].disabled
        info.categories = company.categories
        info.services = company.services
        User.find
          filter:
            where:
              id: info.company.user_id
        .$promise

      .then (users) ->
        throw 'User not found' if users.length == 0
        user = users[0]
        info.user.email = user.email
        LoopbackDirect 
          path: "companies/#{info.company.id}/hidden"
          method: 'get'

      .then (company) ->
        info.company.marketing_code = company.marketing_code
        info.company.marketing_source = company.marketing_source
        info.company.comment = company.comment
        $q.all [

          Company.tickets.count {
            id: info.company.id
          }
          .$promise

          Company.tickets.count {
            id: info.company.id
            where:
              sent_at:
                gt: last24Hours
          }
          .$promise

          Company.tickets.count {
            id: info.company.id
            where:
              sent_at:
                gt: last7Days
          }
          .$promise

          Company.tickets.count {
            id: info.company.id
            where:
              sent_at:
                gt: last30Days
          }
          .$promise

          Event.count {
            where:
              company_id: info.company.id
              action_type: 'init'
          }
          .$promise

          Event.count {
            where:
              company_id: info.company.id
              action_type: 'init'
              sent_at:
                gt: last24Hours
          }
          .$promise

          Event.count {
            where:
              company_id: info.company.id
              action_type: 'init'
              sent_at:
                gt: last7Days
          }
          .$promise

          Event.count {
            where:
              company_id: info.company.id
              action_type: 'init'
              sent_at:
                gt: last30Days
          }
          .$promise

          Event.count {
            where:
              company_id: info.company.id
              action_type: 'init'
              source_widget: true
          }
          .$promise

        ]
      .then (multistats) ->
        info.statistics =
          tickets_all_time: multistats[0].count
          tickets_24_hours: multistats[1].count
          tickets_7_days: multistats[2].count
          tickets_30_days: multistats[3].count
          visitors_all_time: multistats[4].count
          visitors_24_hours: multistats[5].count
          visitors_7_days: multistats[6].count
          visitors_30_days: multistats[7].count
          widget_detected: multistats[8].count > 0
          conversion_rate_all_time: (
            if multistats[4].count > 0 
              Math.floor(100 * multistats[0].count / multistats[4].count) 
            else 0
          )
          conversion_rate_24_hours: (
            if multistats[5].count > 0 
              Math.floor(100 * multistats[1].count / multistats[5].count) 
            else 0
          )
          conversion_rate_7_days: (
            if multistats[6].count > 0
              Math.floor(100 * multistats[2].count / multistats[6].count)
            else 0
          )
          conversion_rate_30_days: (
            if multistats[7].count > 0
              Math.floor(100 * multistats[3].count / multistats[7].count)
            else 0
          )
        info
]