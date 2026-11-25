-- Claude デスクトップアプリを、アカウントごとに分けたデータフォルダで起動する。
-- アプリは 1 つのデータフォルダに 1 つのログイン状態しか持たないため、
-- --user-data-dir でフォルダを分けると別アカウントのアプリとして同時に開ける。
-- アカウントの一覧はリポジトリに置かず、手元の accounts.plist に保存する(名前やフォルダを公開しないため)。

use AppleScript version "2.4"
use framework "Foundation"
use framework "AppKit"
use scripting additions

property claudeApp : "/Applications/Claude.app"
property accountKeys : {"label", "dataDir", "claudeConfigDir", "ghConfigDir"}

-- アプレットは終了時に property の値をスクリプトへ書き戻すため、Cocoa のオブジェクトは global で持つ
global accounts, action, actionIndex, formFields, formAccepted, accountTable

on run
	loadAccounts()
	repeat
		set action to ""
		showChooser()
		if action is "open" then
			openAccount(accounts's objectAtIndex:(actionIndex - 1))
			exit repeat
		else if action is "settings" then
			showSettings()
		else
			exit repeat
		end if
	end repeat
end run

-- ---------------------------------------------------------------- 一覧の保存

on accountsPath()
	return homePath() & "/Library/Application Support/Claude Launcher/accounts.plist"
end accountsPath

on loadAccounts()
	set loaded to current application's NSArray's arrayWithContentsOfFile:(accountsPath())
	if loaded is missing value then
		set accounts to current application's NSMutableArray's array()
		accounts's addObject:(makeAccount({"メイン", "", "", ""}))
		saveAccounts()
	else
		set accounts to loaded's mutableCopy()
	end if
end loadAccounts

on saveAccounts()
	set p to current application's NSString's stringWithString:(accountsPath())
	current application's NSFileManager's defaultManager()'s createDirectoryAtPath:(p's stringByDeletingLastPathComponent()) withIntermediateDirectories:true attributes:(missing value) |error|:(missing value)
	accounts's writeToFile:p atomically:true
end saveAccounts

on makeAccount(values)
	return current application's NSDictionary's dictionaryWithObjects:values forKeys:accountKeys
end makeAccount

on valueOf(account, keyName)
	set v to account's objectForKey:keyName
	if v is missing value then return ""
	return v as text
end valueOf

on accountCount()
	return (accounts's |count|()) as integer
end accountCount

-- ---------------------------------------------------------------- 選択画面

-- choose from list は文字とリストの大きさを変えられないため、大きなボタンを並べたウィンドウを自前で組む
on showChooser()
	set n to accountCount()
	set winWidth to 420
	set buttonHeight to 64
	set gap to 12
	set winHeight to 24 + 96 + 16 + 30 + 24 + n * (buttonHeight + gap) + 12
	set win to makePanel(winWidth, winHeight)
	set content to win's contentView()

	set gearImage to current application's NSImage's imageWithSystemSymbolName:"gearshape" accessibilityDescription:"アカウントの設定"
	set gearImage to gearImage's imageWithSymbolConfiguration:(current application's NSImageSymbolConfiguration's configurationWithPointSize:20 weight:0)
	set gear to (current application's NSButton's buttonWithImage:gearImage target:me action:"settingsClicked:")
	gear's setBordered:false
	gear's setToolTip:"アカウントの設定"
	gear's setFrame:{{winWidth - 16 - 36, winHeight - 12 - 36}, {36, 36}}
	content's addSubview:gear

	-- アイコンはリポジトリに置かず、インストール済みの Claude.app から実行時に読む
	set y to winHeight - 24 - 96
	set iconView to current application's NSImageView's alloc()'s initWithFrame:{{(winWidth - 96) / 2, y}, {96, 96}}
	set icon to current application's NSWorkspace's sharedWorkspace()'s iconForFile:claudeApp
	-- iconForFile: は 32pt の画像を返すため、表示する大きさを指定しないと小さく描画される
	icon's setSize:{96, 96}
	iconView's setImageScaling:(current application's NSImageScaleProportionallyUpOrDown)
	iconView's setImage:icon
	content's addSubview:iconView

	set y to y - 16 - 30
	if n is 0 then
		set promptText to "右上の歯車からアカウントを追加してください"
	else
		set promptText to "どのアカウントで開きますか?"
	end if
	set prompt to current application's NSTextField's labelWithString:promptText
	prompt's setFont:(current application's NSFont's boldSystemFontOfSize:20)
	prompt's setAlignment:(current application's NSTextAlignmentCenter)
	prompt's setFrame:{{0, y}, {winWidth, 30}}
	content's addSubview:prompt

	set y to y - 24
	repeat with i from 1 to n
		set account to accounts's objectAtIndex:(i - 1)
		set title to valueOf(account, "label")
		if runningPid(flagFor(valueOf(account, "dataDir"))) is not "" then set title to title & "(起動中)"
		set y to y - buttonHeight
		set btn to (current application's NSButton's buttonWithTitle:title target:me action:"accountClicked:")
		btn's setTag:i
		btn's setBezelStyle:(current application's NSBezelStyleRegularSquare)
		btn's setFont:(current application's NSFont's systemFontOfSize:22)
		btn's setFrame:{{32, y}, {winWidth - 64, buttonHeight}}
		content's addSubview:btn
		set y to y - gap
	end repeat

	addEscapeButton(content, "closeClicked:")
	runPanel(win)
end showChooser

on accountClicked:sender
	set action to "open"
	set actionIndex to (sender's tag()) as integer
	current application's NSApp's stopModal()
end accountClicked:

on settingsClicked:sender
	set action to "settings"
	current application's NSApp's stopModal()
end settingsClicked:

on closeClicked:sender
	current application's NSApp's stopModal()
end closeClicked:

-- ---------------------------------------------------------------- 設定画面(一覧)

-- macOS のキーボード設定の一覧と同じく、右上の +/- で追加・削除し、行のダブルクリックで編集する
on showSettings()
	set winWidth to 760
	set winHeight to 380
	set win to makePanel(winWidth, winHeight)
	set content to win's contentView()

	set heading to current application's NSTextField's labelWithString:"アカウント"
	heading's setFont:(current application's NSFont's boldSystemFontOfSize:18)
	heading's setFrame:{{24, winHeight - 20 - 26}, {300, 26}}
	content's addSubview:heading

	set specs to {{"plus", "アカウントを追加", "addClicked:"}, {"minus", "選んだアカウントを一覧から外す", "removeClicked:"}}
	repeat with j from 1 to 2
		set spec to item j of specs
		set btn to (current application's NSButton's buttonWithImage:(current application's NSImage's imageWithSystemSymbolName:(item 1 of spec) accessibilityDescription:(item 2 of spec)) target:me action:(item 3 of spec))
		btn's setToolTip:(item 2 of spec)
		btn's setFrame:{{winWidth - 24 - (3 - j) * 36 + 4, winHeight - 20 - 28}, {32, 28}}
		content's addSubview:btn
	end repeat

	set tableTop to winHeight - 20 - 28 - 12
	set tableBottom to 20 + 32 + 12 + 18 + 8
	set scroll to current application's NSScrollView's alloc()'s initWithFrame:{{24, tableBottom}, {winWidth - 48, tableTop - tableBottom}}
	scroll's setHasVerticalScroller:true
	scroll's setBorderType:(current application's NSBezelBorder)
	set accountTable to current application's NSTableView's alloc()'s initWithFrame:{{0, 0}, {winWidth - 48, tableTop - tableBottom}}
	set columns to {{"label", "表示名", 110}, {"dataDir", "データフォルダ", 170}, {"claudeConfigDir", "会話履歴のフォルダ", 200}, {"ghConfigDir", "GitHub CLI の設定", 210}}
	repeat with c in columns
		set column to (current application's NSTableColumn's alloc()'s initWithIdentifier:(item 1 of c))
		column's setTitle:(item 2 of c)
		column's setWidth:(item 3 of c)
		-- 書き換えできる列のままだと、ダブルクリックがセルの書き換えになり編集画面が開かない
		column's setEditable:false
		(accountTable's addTableColumn:column)
	end repeat
	accountTable's setRowHeight:24
	accountTable's setUsesAlternatingRowBackgroundColors:true
	accountTable's setDataSource:me
	accountTable's setTarget:me
	accountTable's setDoubleAction:"rowDoubleClicked:"
	scroll's setDocumentView:accountTable
	content's addSubview:scroll

	set hint to current application's NSTextField's labelWithString:"行をダブルクリックすると編集できます。変更は、そのアカウントを次に起動したときから適用されます。"
	hint's setFont:(current application's NSFont's systemFontOfSize:12)
	hint's setTextColor:(current application's NSColor's secondaryLabelColor())
	hint's setFrame:{{24, tableBottom - 8 - 18}, {winWidth - 48, 18}}
	content's addSubview:hint

	set doneButton to (current application's NSButton's buttonWithTitle:"完了" target:me action:"closeClicked:")
	doneButton's setKeyEquivalent:return
	doneButton's setFrame:{{winWidth - 24 - 104, 20}, {104, 32}}
	content's addSubview:doneButton
	addEscapeButton(content, "closeClicked:")

	runPanel(win)
end showSettings

on numberOfRowsInTableView:aTableView
	return accountCount()
end numberOfRowsInTableView:

on tableView:aTableView objectValueForTableColumn:aColumn row:aRow
	set columnKey to (aColumn's identifier()) as text
	set v to valueOf(accounts's objectAtIndex:aRow, columnKey)
	if v is "" then return defaultLabel(columnKey)
	return v
end tableView:objectValueForTableColumn:row:

-- 空欄のときに実際に使われる場所を出す(「既定」だけでは、どこを使うのか分からないため)
on defaultLabel(columnKey)
	if columnKey is "dataDir" then return "Claude(デフォルト値)"
	if columnKey is "claudeConfigDir" then return "~/.claude(デフォルト値)"
	if columnKey is "ghConfigDir" then return "~/.config/gh(デフォルト値)"
	return ""
end defaultLabel

on rowDoubleClicked:sender
	set r to (accountTable's clickedRow()) as integer
	if r < 0 then return
	set edited to editAccount(accounts's objectAtIndex:r, r + 1)
	if edited is missing value then return
	accounts's replaceObjectAtIndex:r withObject:edited
	saveAccounts()
	accountTable's reloadData()
end rowDoubleClicked:

on addClicked:sender
	set edited to editAccount(missing value, 0)
	if edited is missing value then return
	accounts's addObject:edited
	saveAccounts()
	accountTable's reloadData()
end addClicked:

on removeClicked:sender
	set r to (accountTable's selectedRow()) as integer
	if r < 0 then
		display alert "一覧から外すアカウントを選んでください。" as warning
		return
	end if
	set removing to valueOf(accounts's objectAtIndex:r, "label")
	try
		display dialog "「" & removing & "」をランチャーの一覧から外します。データフォルダと会話履歴は削除しません。" buttons {"キャンセル", "外す"} default button "外す" cancel button "キャンセル" with title "Claude Launcher"
	on error number -128
		return
	end try
	accounts's removeObjectAtIndex:r
	saveAccounts()
	accountTable's reloadData()
end removeClicked:

-- ---------------------------------------------------------------- 設定画面(1 件の編集)

-- account が missing value なら追加。editingIndex は重複の検査で自分自身を除くために使う(追加は 0)
on editAccount(account, editingIndex)
	if account is missing value then
		set values to {"", "", "", ""}
	else
		set values to {}
		repeat with k in accountKeys
			set end of values to valueOf(account, k as text)
		end repeat
	end if
	repeat
		set values to showForm(values)
		if values is missing value then return missing value
		set problem to validate(values, editingIndex)
		if problem is "" then return makeAccount(values)
		display alert problem as warning
	end repeat
end editAccount

on validate(values, editingIndex)
	if item 1 of values is "" then return "表示名を入れてください。"
	if (item 2 of values) contains "/" then return "データフォルダ名にはフォルダの名前だけを入れてください(/ は使えません)。"
	repeat with i from 1 to accountCount()
		if i is not editingIndex then
			set other to accounts's objectAtIndex:(i - 1)
			if valueOf(other, "label") is (item 1 of values) then return "「" & (item 1 of values) & "」という表示名はすでにあります。"
			-- 同じデータフォルダは同じログイン状態になるため、2 つのアカウントで共有させない
			if valueOf(other, "dataDir") is (item 2 of values) then return "このデータフォルダは「" & valueOf(other, "label") & "」が使っています。"
		end if
	end repeat
	return ""
end validate

on showForm(values)
	set formAccepted to false
	set formFields to {}
	set winWidth to 560
	set rowHeight to 28
	set rowGap to 14
	set rows to {{"表示名", "例: メイン", false}, {"データフォルダ名", "空欄なら Claude(デフォルト値)", false}, {"会話履歴のフォルダ", "空欄なら ~/.claude(デフォルト値)", true}, {"GitHub CLI の設定フォルダ", "空欄なら ~/.config/gh(デフォルト値)", true}}
	set winHeight to 20 + 26 + 8 + 34 + 16 + 4 * (rowHeight + rowGap) + 10 + 32 + 20
	set win to makePanel(winWidth, winHeight)
	set content to win's contentView()

	set y to winHeight - 20 - 26
	set heading to current application's NSTextField's labelWithString:"アカウントの設定"
	heading's setFont:(current application's NSFont's boldSystemFontOfSize:18)
	heading's setFrame:{{24, y}, {winWidth - 48, 26}}
	content's addSubview:heading

	set y to y - 8 - 34
	set hint to current application's NSTextField's wrappingLabelWithString:"データフォルダ名は ~/Library/Application Support/ の下のフォルダの名前です。変更は、そのアカウントを次に起動したときから適用されます。"
	hint's setFont:(current application's NSFont's systemFontOfSize:12)
	hint's setTextColor:(current application's NSColor's secondaryLabelColor())
	hint's setFrame:{{24, y}, {winWidth - 48, 34}}
	content's addSubview:hint

	set y to y - 16
	repeat with i from 1 to 4
		set spec to item i of rows
		set y to y - rowHeight
		set caption to (current application's NSTextField's labelWithString:(item 1 of spec))
		caption's setFont:(current application's NSFont's systemFontOfSize:14)
		caption's setFrame:{{24, y + 4}, {180, 20}}
		content's addSubview:caption
		set fieldWidth to winWidth - 24 - 210
		if item 3 of spec then set fieldWidth to fieldWidth - 84
		set field to (current application's NSTextField's textFieldWithString:(item i of values))
		field's setPlaceholderString:(item 2 of spec)
		field's setFont:(current application's NSFont's systemFontOfSize:14)
		field's setFrame:{{210, y}, {fieldWidth, rowHeight}}
		content's addSubview:field
		set end of formFields to field
		if item 3 of spec then
			set picker to (current application's NSButton's buttonWithTitle:"選ぶ…" target:me action:"chooseFolderClicked:")
			picker's setTag:i
			picker's setFrame:{{winWidth - 24 - 76, y}, {76, rowHeight}}
			content's addSubview:picker
		end if
		set y to y - rowGap
	end repeat

	set cancelButton to (current application's NSButton's buttonWithTitle:"キャンセル" target:me action:"closeClicked:")
	cancelButton's setKeyEquivalent:(character id 27)
	cancelButton's setFrame:{{winWidth - 24 - 220, 20}, {104, 32}}
	content's addSubview:cancelButton
	set okButton to (current application's NSButton's buttonWithTitle:"保存" target:me action:"formSaveClicked:")
	okButton's setKeyEquivalent:return
	okButton's setFrame:{{winWidth - 24 - 104, 20}, {104, 32}}
	content's addSubview:okButton

	runPanel(win)
	if not formAccepted then return missing value
	set collected to {}
	repeat with field in formFields
		set end of collected to trimmed((field's stringValue()) as text)
	end repeat
	return collected
end showForm

on chooseFolderClicked:sender
	set panel to current application's NSOpenPanel's openPanel()
	panel's setCanChooseDirectories:true
	panel's setCanChooseFiles:false
	panel's setCanCreateDirectories:true
	-- 会話履歴の既定の置き場(~/.claude など)は隠しフォルダのため、表示しないと選べない
	panel's setShowsHiddenFiles:true
	if (panel's runModal()) as integer is 1 then
		set chosenPath to (panel's |URL|()'s |path|()) as text
		set field to item ((sender's tag()) as integer) of formFields
		field's setStringValue:(collapseHome(chosenPath))
	end if
end chooseFolderClicked:

on formSaveClicked:sender
	set formAccepted to true
	current application's NSApp's stopModal()
end formSaveClicked:

-- ---------------------------------------------------------------- ウィンドウの共通処理

on makePanel(winWidth, winHeight)
	set styleMask to (current application's NSWindowStyleMaskTitled as integer) + (current application's NSWindowStyleMaskClosable as integer)
	set win to current application's NSPanel's alloc()'s initWithContentRect:{{0, 0}, {winWidth, winHeight}} styleMask:styleMask backing:(current application's NSBackingStoreBuffered) defer:false
	win's setTitle:"Claude Launcher"
	win's setDelegate:me
	return win
end makePanel

-- 見えるボタンを置かずに esc キーで閉じられるよう、大きさ 0 のボタンに esc を割り当てる
on addEscapeButton(content, handlerName)
	set btn to (current application's NSButton's buttonWithTitle:"" target:me action:handlerName)
	btn's setKeyEquivalent:(character id 27)
	btn's setFrame:{{0, 0}, {0, 0}}
	content's addSubview:btn
end addEscapeButton

on runPanel(win)
	win's |center|()
	current application's NSApp's activateIgnoringOtherApps:true
	win's makeKeyAndOrderFront:me
	current application's NSApp's runModalForWindow:win
	win's orderOut:me
end runPanel

-- 閉じるボタンで閉じたときもモーダルを抜ける
on windowWillClose:aNotification
	current application's NSApp's stopModal()
end windowWillClose:

-- ---------------------------------------------------------------- 起動

on openAccount(account)
	set flag to flagFor(valueOf(account, "dataDir"))
	set pid to runningPid(flag)
	if pid is not "" then
		-- 同じデータフォルダで 2 つ目を起動すると、アプリ側の多重起動の制御に委ねることになる。
		-- 起動済みならそのプロセスを前面に出すだけにする。環境変数は起動中のプロセスには反映されない。
		tell application "System Events" to set frontmost of (first process whose unix id is (pid as integer)) to true
		return
	end if
	-- Dock から起動したランチャーはシェルの環境変数を持たないため、会話履歴の場所は --env で明示的に渡す
	set command to "open -n -a " & quoted form of claudeApp
	set claudeDir to expandHome(valueOf(account, "claudeConfigDir"))
	if claudeDir is not "" then set command to command & " --env " & quoted form of ("CLAUDE_CONFIG_DIR=" & claudeDir)
	set ghDir to expandHome(valueOf(account, "ghConfigDir"))
	if ghDir is not "" then set command to command & " --env " & quoted form of ("GH_CONFIG_DIR=" & ghDir)
	if flag is not "" then set command to command & " --args " & quoted form of flag
	do shell script command
end openAccount

on flagFor(dataDir)
	if dataDir is "" then return ""
	return "--user-data-dir=" & homePath() & "/Library/Application Support/" & dataDir
end flagFor

-- 既定のフォルダのプロセスは --user-data-dir を持たないので、引数の有無で見分ける。
on runningPid(flag)
	set exe to claudeApp & "/Contents/MacOS/Claude"
	if flag is "" then
		set padded to ""
	else
		set padded to " " & flag & " "
	end if
	set program to "$2 == exe && (length(f) == 0 ? index($0, any) == 0 : index($0 OFS, f) > 0) { print $1; exit }"
	return do shell script "ps -axo pid=,args= | awk -v exe=" & quoted form of exe & " -v f=" & quoted form of padded & " -v any=--user-data-dir= " & quoted form of program
end runningPid

-- ---------------------------------------------------------------- パスと文字列

-- AppleScriptObjC の中では path to home folder が失敗するため、Foundation から取る(末尾に / は付かない)
on homePath()
	return (current application's NSHomeDirectory()) as text
end homePath

on expandHome(p)
	if p is "~" then return homePath()
	if p starts with "~/" then return homePath() & (text 2 thru -1 of p)
	return p
end expandHome

on collapseHome(p)
	set h to homePath()
	if p is h then return "~"
	if p starts with (h & "/") then return "~" & (text ((length of h) + 1) thru -1 of p)
	return p
end collapseHome

on trimmed(s)
	return ((current application's NSString's stringWithString:s)'s stringByTrimmingCharactersInSet:(current application's NSCharacterSet's whitespaceAndNewlineCharacterSet())) as text
end trimmed
