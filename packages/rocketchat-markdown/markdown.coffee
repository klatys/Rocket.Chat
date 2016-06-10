###
# Markdown is a named function that will parse markdown syntax
# @param {Object} message - The message object
###

class Markdown
	constructor: (message) ->
		msg = message

		if not _.isString message
			if _.trim message?.html
				msg = message.html
			else
				return message
		# Support `text`
		if _.isString message
			msg = msg.replace(/(^|&gt;|[ >_*~])\`([^`\r\n]+)\`([<_*~]|\B|\b|$)/gm, '$1<span class="copyonly">`</span><span><code class="inline">$2</code></span><span class="copyonly">`</span>$3')
		else
			message.tokens ?= []
			msg = msg.replace /(^|&gt;|[ >_*~])\`([^`\r\n]+)\`([<_*~]|\B|\b|$)/gm, (match, p1, p2, p3, offset, text) ->
				token = "=&=#{Random.id()}=&="

				message.tokens.push
					token: token
					text: "#{p1}<span class=\"copyonly\">`</span><span><code class=\"inline\">#{p2}</code></span><span class=\"copyonly\">`</span>#{p3}"

				return token

		schemes = RocketChat.settings.get('Markdown_SupportSchemesForLink').split(',').join('|')

		# Support ![alt text](http://image url)
		msg = msg.replace(new RegExp("!\\[([^\\]]+)\\]\\(((?:#{schemes}):\\/\\/[^\\)]+)\\)", 'gm'), '<a href="$2" title="$1" class="swipebox" target="_blank"><div class="inline-image" style="background-image: url($2);"></div></a>')

		# Support [Text](http://link)
		msg = msg.replace(new RegExp("\\[([^\\]]+)\\]\\(((?:#{schemes}):\\/\\/[^\\)]+)\\)", 'gm'), '<a href="$2" target="_blank">$1</a>')

		# Support <http://link|Text>
		#msg = msg.replace(new RegExp("(?:<|&lt;)((?:#{schemes}):\\/\\/[^\\|]+)\\|(.+?)(?=>|&gt;)(?:>|&gt;)", 'gm'), '<a href="$1" target="_blank">$2</a>')

		if RocketChat.settings.get('Markdown_Headers')
			# Support # Text for h1
			msg = msg.replace(/^# (([\S\w\d-_\/\*\.,\\][ \u00a0\u1680\u180e\u2000-\u200a\u2028\u2029\u202f\u205f\u3000\ufeff]?)+)/gm, '<h1>$1</h1>')

			# Support # Text for h2
			msg = msg.replace(/^## (([\S\w\d-_\/\*\.,\\][ \u00a0\u1680\u180e\u2000-\u200a\u2028\u2029\u202f\u205f\u3000\ufeff]?)+)/gm, '<h2>$1</h2>')

			# Support # Text for h3
			msg = msg.replace(/^### (([\S\w\d-_\/\*\.,\\][ \u00a0\u1680\u180e\u2000-\u200a\u2028\u2029\u202f\u205f\u3000\ufeff]?)+)/gm, '<h3>$1</h3>')

			# Support # Text for h4
			msg = msg.replace(/^#### (([\S\w\d-_\/\*\.,\\][ \u00a0\u1680\u180e\u2000-\u200a\u2028\u2029\u202f\u205f\u3000\ufeff]?)+)/gm, '<h4>$1</h4>')

		# Support *text* to make bold
		msg = msg.replace(/(^|&gt;|[ >_~`])\*{1,2}([^\*\r\n]+)\*{1,2}([<_~`]|\B|\b|$)/gm, '$1<span class="copyonly">*</span><strong>$2</strong><span class="copyonly">*</span>$3')

		# Support _text_ to make italics
		msg = msg.replace(/(^|&gt;|[ >*~`])\_([^\_\r\n]+)\_([<*~`]|\B|\b|$)/gm, '$1<span class="copyonly">_</span><em>$2</em><span class="copyonly">_</span>$3')

		# Support ~text~ to strike through text
		msg = msg.replace(/(^|&gt;|[ >_*`])\~{1,2}([^~\r\n]+)\~{1,2}([<_*`]|\B|\b|$)/gm, '$1<span class="copyonly">~</span><strike>$2</strike><span class="copyonly">~</span>$3')

		# Support [ ] and [x] for task list
		msg = msg.replace(/\[(x| )\](?=\s)/igm, (match, checked) ->
			return '<span class="copyonly">['+checked+'] </span><input type="checkbox" disabled ' + (if checked is ' ' then '' else 'checked ') + '/>'
		)

		#add table support
		#Copyright (c) 2011-2014, Christopher Jeffrey (https://github.com/chjj/)
		msg = msg.replace(/^ *\|(.+)\n *\|( *[-:]+[-| :]*)\n((?: *\|.*(?:\n|$))*)\n*/igm, (match) ->
			matches = /^ *\|(.+)\n *\|( *[-:]+[-| :]*)\n((?: *\|.*(?:\n|$))*)\n*/.exec(match)

			header = body = ""
			
			item =
				type: 'table'
				header: matches[1].replace(/^ *| *\| *$/g, '').split(RegExp(' *\\| *'))
				align: matches[2].replace(/^ *|\| *$/g, '').split(RegExp(' *\\| *'))
				cells: matches[3].replace(/(?: *\| *)?\n$/, '').split('\n')
			i = 0
			while i < item.align.length
				if /^ *-+: *$/.test(item.align[i])
					item.align[i] = 'right'
				else if /^ *:-+: *$/.test(item.align[i])
					item.align[i] = 'center'
				else if /^ *:-+ *$/.test(item.align[i])
					item.align[i] = 'left'
				else
					item.align[i] = null
				i++
			i = 0
			while i < item.cells.length
				item.cells[i] = item.cells[i].replace(/^ *\| *| *\| *$/g, '').split(RegExp(' *\\| *'))
				i++
			i = 0
			while i < item.header.length
				flags =
					header: true
					align: item.align[i]
				cell += Markdown.tableCell(item.header[i],
					header: true
					align: item.align[i])
				i++
			header += Markdown.tableRow(cell)
			i = 0
			while i < item.cells.length
				row = item.cells[i]
				cell = ''
				j = 0
				while j < row.length
					cell += Markdown.tableCell(row[j],
						header: false
						align: item.align[j])
					j++
				body += Markdown.tableRow(cell)
				i++
			Markdown.table header, body
		)

		#add list support
		String::repeat = (num) ->
			new Array(num + 1).join this

		previousLevel = 0
		msg = msg.replace(/^([\s{2}|\t]*?)[*|\-]\s(.*)/gm, (match, level, text) ->
			actualLevel = 1
			if level
				spaceLevel = ((level.match(/\s{2}/g) or []).length) + 1
				tabLevel = ((level.match(/\t/g) or []).length) + 1 
				actualLevel = Math.max(spaceLevel, tabLevel, 1)

			'<ul><li class="indent">'.repeat(actualLevel-1) + '<ul><li><span class="copyonly">'+level+'</span>' + text + '</li></ul>'.repeat(actualLevel)
		)
		msg = msg.replace(/<\/ul>\n<ul>/gm, '').replace(/<ul>/,'<ul style="list-style:square">')

		#support for horizontal line
		msg = msg.replace(/(\*\*\*|---|___)/igm, (match) ->
			return '<span class="copyonly">['+match+'] </span><hr />'
		)


		# Support for block quote
		# >>>
		# Text
		# <<<
		msg = msg.replace(/(?:&gt;){3}\n+([\s\S]*?)\n+(?:&lt;){3}/g, '<blockquote><span class="copyonly">&gt;&gt;&gt;</span>$1<span class="copyonly">&lt;&lt;&lt;</span></blockquote>')

		# Support >Text for quote
		msg = msg.replace(/^&gt;(.*)$/gm, '<blockquote><span class="copyonly">&gt;</span>$1</blockquote>')

		# Remove white-space around blockquote (prevent <br>). Because blockquote is block element.
		msg = msg.replace(/\s*<blockquote>/gm, '<blockquote>')
		msg = msg.replace(/<\/blockquote>\s*/gm, '</blockquote>')

		# Remove new-line between blockquotes.
		msg = msg.replace(/<\/blockquote>\n<blockquote>/gm, '</blockquote><blockquote>')

		if not _.isString message
			message.html = msg
		else
			message = msg

		console.log 'Markdown', message if window?.rocketDebug

		return message

	@tableCell: (content, flags) ->
		type = if flags.header then 'th' else 'td'
		tag = if flags.align then '<' + type + ' style="text-align:' + flags.align + '">' else '<' + type + '>'
		return tag + content + '</' + type + '>\n'

	@table: (header, body) ->
		return '<table>\n' + '<thead>\n' + header + '</thead>\n' + '<tbody>\n' + body + '</tbody>\n' + '</table>\n'

	@tableRow: (content) ->
		return '<tr>\n' + content + '</tr>\n'

RocketChat.callbacks.add 'renderMessage', Markdown, RocketChat.callbacks.priority.HIGH
RocketChat.Markdown = Markdown

if Meteor.isClient
	Blaze.registerHelper 'RocketChatMarkdown', (text) ->
		return RocketChat.Markdown text
