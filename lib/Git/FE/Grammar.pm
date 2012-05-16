use v6;
# use Grammar::Tracer;

grammar Git::FE::Grammar; 

token TOP {
	^ <commit>
}
regex person-name {
[<-['<']>*] )> \s
}
token person {
	<.ident> \s[ $<name>=<person-name>]?
	'<' ~ '>' $<email>=[<-['>']>*] \s
	<timestamp> \n
}

token timestamp {
	$<time>=[\d+] \s $<offset>=[<[+-]>\d ** 4]
}
token change { <filecopy> | <filerename> | <filedelete> | <filemodify> }

token filecopy {
	'C' \s $<source>=.<path> \s $<dest>=<.path> \n
}

token filerename {
	'R' \s $<source>=<.path> \s $<dest>=<.path> \n
}

token filedelete {
	'D' \s <path> \n
}

token filemodify {
	'M' \s <mode> \s 
		[
		| <dataref> \s <path> \n
		| 'inline' \s <path> \n
		<data>
		]
}

token mark { 'mark' \s ':'(\d+) \n }

token data {
	'data' \s
	[
	| '<<' ~ \n $<end>=<.ident> 
		~ [<?after \n> $<end>] $<contents>=(.*)
	| <contents=data_length>
	# $<length>=[\d+] \n 
	
	] \n?
	{ say $<contents> }
}

# HACK: . ** {$<length>} doesn't work yet
regex data_length {
	(\d+) \n
	:my $p; { $p = $/.CURSOR.pos }
	<( .*? <?at($p+$0)>
}
token length { \d+ }

token committish {
	| <branch_name>
	| ':' $<mark>=[\d+]
	| <sha1>
	| \N+
}

token dataref {
	| ':' $<mark>=[\d+]
	| <sha1>
}

token path {
	 <-["\n]> \N+
	| '"' ~ '"' [['\"'|<-["]>]*]
}

token sha1 {
	<.xdigit> ** 40
}


token commit {
	'commit ' <branch_name> \n
	<mark>?
	[<?before 'author'>:$<author>=<person>]?
	<?before 'committer'>:$<committer> = <person>
	$<message>=<data>
	['from ' $<from>=<.committish>]?
	['merge ' $<merge>=<.committish>]*
	<change>*
}

token mode {
	| 100644 | 644 # normal file
	| 100755 | 755 # executable file
	| 120000       # symlink
	| 160000       # gitlink
	| 040000       # subdirectory
}




token branch_name { <.ident>* % \/ }

