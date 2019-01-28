Express     = require 'express'
HTTP        = require 'request-promise'
_           = require 'lodash'
Moment      = require 'moment'
HTMLClean   = require('htmlclean')

# Const
PORT = process.env.PORT or 3000

# App
App = Express()
Moment.locale 'vi'

# Routes
App.get '/posts', (req, res) ->
  try
    jQuery = await HTTP(
      uri: 'https://toplist.vn?a=POST&p=' + (req.query.page or 1)
      transform: (body) -> require('cheerio').load body
    )

    results = []

    # Posts
    jQuery('.container').find('.media').each((index, element) ->
      # Info
      id          = _.split(_.toString(jQuery(element).find('.media-heading').find('a').attr('href')), /[-]+/).pop().replace '.htm', ''
      title       = jQuery(element).find('.media-heading').text()
      thumb_url   = 'https://toplist.vn' + jQuery(element).find('.round_img').attr 'src'
      description = jQuery(element).find('.hidden-xs').text().trim()

      # Meta
      meta        = jQuery(element).find('.text-muted')
      author      = 
        id: parseInt(_.split(_.toString(meta.find('a').attr('href')), /[-]+/).pop().replace('/', ''), 10)
        name: _.toString(meta.find('a').attr('title')).trim()
        avatar_url: meta.find('.user_avatar_link').attr 'src'
      total       = _.trim(_.toString(meta.html()).replace(/\n/g, '').split(/<i class=\"fa fa-bars\" aria-hidden=\"true\"><\/i>(.*)<i class=\"fa fa-eye\"/g)[1])
      views       = _.trim(_.toString(meta.html()).replace(/\n/g, '').split(/<i class=\"fa fa-eye\" aria-hidden=\"true\"><\/i>(.*)<i class=\"fa fa-heart\"/g)[1])
      updated_at  = _.trim(_.toString(meta.html()).replace(/\n/g, '').split(/<\/a>(.*)<i class=\"fa fa-bars\"/g)[1])
      created_at  = _.trim(_.toString(meta.html()).replace(/\n/g, '').split(/<\/a>(.*)<i class=\"fa fa-bars\"/g)[1])

      # Put to list if `title` not empty
      if (title != '')
        results.push(
          id: parseInt id, 10
          title: title
          thumb_url: thumb_url
          description: description
          author: author
          total: parseInt total, 10
          views: parseInt views, 10
          updated_at: Moment(updated_at, 'DD-MM-YYYY').format 'YYYY-MM-DD HH:mm:ss'
          created_at: Moment(created_at, 'DD-MM-YYYY').format 'YYYY-MM-DD HH:mm:ss'
        )
    )

    res.json results
  catch error
    console.error error.message
    res.status(500).send 'Sự cố máy chủ!'

App.get '/posts/:id', (req, res) ->
  try
    jQuery = await HTTP(
      uri: 'https://toplist.vn/top-list/best-sona-' + req.params.id + '.htm'
      transform: (body) -> require('cheerio').load body
    )

    element     = jQuery('.post_header')

    # Info
    id          = _.split(_.toString(jQuery(element).find('.media-heading').find('a').attr('href')), /[-]+/).pop().replace '.htm', ''
    title       = jQuery(element).find('h1').text()
    thumb_url   = jQuery('meta[property="og:image"]').attr 'content'
    description = jQuery(element).find('.post_dsp_desc').text().trim()

    # Meta
    meta        = jQuery(element).find('.text-muted')
    total       = _.trim(_.toString(meta.html()).replace(/\n/g, '').split(/<i class=\"fa fa-bars\" aria-hidden=\"true\"><\/i>(.*)<i class=\"fa fa-eye\"/g)[1])
    views       = _.trim(_.toString(meta.html()).replace(/\n/g, '').split(/<i class=\"fa fa-eye\" aria-hidden=\"true\"><\/i>(.*)<i class=\"fa fa-heart\"/g)[1])
    updated_at  = _.trim(_.toString(meta.html()).replace(/\n/g, '').split(/<\/i>(.*)<i class=\"fa fa-bars\"/g)[1])
    created_at  = _.trim(_.toString(meta.html()).replace(/\n/g, '').split(/<\/i>(.*)<i class=\"fa fa-bars\"/g)[1])
    
    result =
      id: parseInt req.params.id, 10
      title: title
      thumb_url: thumb_url
      description: description
      total: parseInt total, 10
      views: parseInt views, 10
      items: []
      updated_at: Moment(updated_at, 'DD-MM-YYYY').format 'YYYY-MM-DD HH:mm:ss'
      created_at: Moment(created_at, 'DD-MM-YYYY').format 'YYYY-MM-DD HH:mm:ss'

    jQuery('.post_content').find('.item_dsp_row').each((index, element) ->
      if (jQuery(element).find('a').attr('name'))
        author      = 
          id: parseInt(_.split(_.toString(jQuery(element).find('.media-left').find('a').attr('href')), /[-]+/).pop().replace('/', ''), 10)
          name: _.toString(jQuery(element).find('.media-left').find('a').attr('title')).trim()
          avatar_url: jQuery(element).find('.media-left').find('.user_avatar_link').attr 'src'
        content     = _.toString(jQuery(element).find('.media-body').html()).trim().split('</h4>')[1].split('<a name="comment')[0]
        updated_at  = _.toString(jQuery(element).find('.media-left').html()).replace(/\n/g, '').split(/<br>(.*)+<\/center/g)[1].trim()
        created_at  = _.toString(jQuery(element).find('.media-left').html()).replace(/\n/g, '').split(/<br>(.*)+<\/center/g)[1].trim()

        result.items.push(
          id: parseInt(_.toString(jQuery(element).find('a').attr('name')).replace('item', ''), 10)
          title: jQuery(element).find('.media-heading').text()
          content: HTMLClean(content)
          author: author
          updated_at: Moment(updated_at, 'YYYY-MM-DD HH:mm:ss').format 'YYYY-MM-DD HH:mm:ss'
          created_at: Moment(created_at, 'YYYY-MM-DD HH:mm:ss').format 'YYYY-MM-DD HH:mm:ss'
        )
    )

    res.json result
  catch error
    console.error error.message
    res.status(500).send 'Sự cố máy chủ!'

App.get '/lists', (req, res) ->
  try
    jQuery = await HTTP(
      uri: 'https://toplist.vn'
      transform: (body) -> require('cheerio').load body
    )

    results = []
    type    = 0

    jQuery('.main-dropdown-menu').find('> *').each((index, element) ->
      if (jQuery(element).prop('tagName') == 'DIV')
        ++type
      else if (jQuery(element).text() != '')
        slug = _.toString(jQuery(element).attr('href')).split('/')[2]

        if (type == 0)
          slug = _.toString(jQuery(element).attr('href')).split('/')[1]

        results.push(
          title: jQuery(element).text()
          slug: slug
          type: type
        )
    )

    res.json results
  catch error
    console.error error.message
    res.status(500).send 'Sự cố máy chủ!'

# Run
App.listen(PORT, ->
  console.info '_> Đã chạy ứng dụng ở cổng: ' + PORT
)
