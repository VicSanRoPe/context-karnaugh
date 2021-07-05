# context-karnaugh

This is a ConTeXt module that draws Karnaugh maps containing data (ones, ceros, or anything) and their groupings, with easy to use syntax. It supports larger than four variable maps; and formulas, or any text, can be added.

The PDF documentation (with the actual maps) is [here](https://github.com/VicSanRoPe/context-karnaugh/doc/context/third/karnaugh/karnaugh-docs.pdf)

Options
======

To draw a Karnaugh map, the `karnaugh` environment is used, the options specified here
override the global options.
```
\startkarnaugh [..,..=..,..] ... \stopkarnaugh
```

The options are set globally with the `setupkarnaugh` command.
```
\setupkarnaugh [..,..=..,..]
	ylabels = LIST
	xlabels = LIST
	ny = NUMBER
	nx = NUMBER
	name = TEXT
	labelstyle = edge corner
	groupstype = pass stop
	indices = yes no on off
	spacing = small big normal NUMBER
	indicesstart = NUMBER
```


* The options `ylabels` and `xlabels` are the input variables used for the map, they are written as a list, and math mode is usually used for each individual element. `xlabels` refers to the variables at the top of the map, and the last element is the least significant variable (for indices and minterms). `ylabels` are at the left, its first element is the most significant variable. If these labels are not specified, then the labels will be I<sub>0</sub> , I<sub>1</sub> , I<sub>2</sub>, and so on.

* The options `ny` and `nx` are the map’s size in number of cells, they are calculated automatically when labels are specified, and if no size or labels are specified but there is data, the size of the map is guessed with the newline characters. Thus, the following produces an empty map with default labels.

* The `name` option is some text that is added on top or on the top-left corner of the map, the name of the function could be placed there.

* The `labelstyle` option specifies whether the input variables are placed in a corner of the map (value: corner) or at the edges (value: edge). By default, the corner style is used for small maps and the edge style is used for 5 variable maps or larger.

* The `groupstyle` option changes how the group’s lines are drawn, if its value is pass (the default), the lines continue for a bit outside of the map. If it is stop, they will not, which might be preferred when making a combination of maps using the overlay method, to mark that some adjacent groups are not connected, but the effect is minimal.

* If the `indices` option is set to yes or on, it will draw a small number on every cell with the value of the input variables in decimal. If groups are also being drawn, the map’s spacing will be enlarged to acomodate both things and the data.

* The `spacing` option simply increases or decreases the whitespace around every cell’s data.
Please note that the document’s font size affects the map’s size, such that is looks the same, just smaller or bigger, always with the same font as the main text. To make the maps have a constant size, surround them with \scale. spacing can be a number too, adjust both of these to get the proportions you want.




Data input
=======
As a list
-------
```
\karnaughtabledata {...,...}
```

This command fills the map with the elements specified in the comma separated list in the same order as the truth table. Space before and after a comma is ignored. If all elements are just one simple character (very common), then the elements may be written one after the other, with no commas or spaces. The map’s size is calculated automatically if no size or labels are given. The elements aren’t limited to ceros and ones, they just have to be short.


```
\karnaughminterms {...,...}
\karnaughmaxterms {...,...}
```
These commands place ones or ceros (respectively) on the specified locations (written as a list of the decimal values of the input variables) and then fill the rest of the map with the opposite symbol.
```tex
\startkarnaugh[ylabels={A}, xlabels={B}]
	\karnaughminterms{0, 3}
\stopkarnaugh
```


As a map
-------
```
\startkarnaughdata ... \stopkarnaughdata
```
Inside of this environment the data is placed as a comma separated list, preferably with newlines at every row, in the same positions as they will appear on the map. A trailing comma is ignored, and cells may be left empty.
```tex
\startkarnaugh[ylabels={d, c}, xlabels={b, a}]
	\startkarnaughdata
		1,	0,	1,	0,
		0,	1,	1,	0,
		1,	0,	1,	0,
		0,	1,	1,	0,
	\stopkarnaughdata
\stopkarnaugh
```



Groups and other data
========

This data is input with the map syntax because presumably the map is already drawn with the
ones and ceros, and drawing the groups “in-place” is much easier than calculating the coordinates
of the desired groups.
```
\startkarnaughgroups ... \stopkarnaughgroups``
```
Inside of this environment various types of data are placed as a comma separated list with as many elements as there are cells in the map. Any cell may contain various instances of any of the information types mentioned here.



Groups
-------
Groups are input by inserting a letter (one per group) on every cell the group covers. The way they are drawn is handled automatically. The first few uppercase letters have colors assigned to them. The following example shows three groups: at the corners, the edges, and in the middle.
```tex
\startkarnaugh[ny=4, nx=4]
	\startkarnaughgroups
		BA,	,	,	BA,
		B,	C,	C,	B,
		,	C,	C,	,
		A,	,	,	A,
	\stopkarnaughgroups
\stopkarnaugh
```



Notes
-------
After drawing a Karnaugh map, it is useful to know which term of the produced formula represents each group. These can be drawn as text with arrows coming from the desired group.
```
\karnaughnote {...}{...}{...}
	CHARACTER
	CONTENT
	tr Tr tl Tl br Br bl Bl lb lt rb rt r b
```
The base of the arrow is specified in the `karnaughgroups` environment as an asterisk after the group it represents, and the remaining data is specified using the karnaughnote command. The first argument is the character assigned to the group, the second is the text to be added to the map, and the third is one of the specified directions the arrow may point to.

The first letter of the direction is where it will mainly point towards, with `t` meaning top, `b` meaning bottom, `l` meaning left, and `r` meaning right; if it is uppercase it will be further separated from the map (for two rows of text, for example). The second letter (if present) will be a slight offset to the desired side, mainly to make the arrow not overlap with the grey code to the top and left. The arrows look better when they come out of a group’s corner.

```tex
\startkarnaugh[ny=4, nx=4]
	\startkarnaughgroups
		B*A,	,	,	BA,
		B,	C,	C,	B,
		,	C,	C*,	,
		A*,	,	,	A,
	\stopkarnaughgroups
	\karnaughnote{A}{A's note}{b}
	\karnaughnote{B}{B's note}{Tr}
	\karnaughnote{C}{C's note}{rb}
\stopkarnaugh
```


Connecting lines
-------
This feature is only used when drawing Karnaugh maps with more than 4 variables, then a mirror line is drawn in the middle, and groups which exist in both halves should be connected to each other.

To draw connections, a single plus `+` is placed in the karnaughgroups environment after the letter of the group to be connected, and at least one minus `-` has to be placed after the letter of a different region of the group.

The following example shows:
* The group `A` which is mirrored on both axis and has 3 lines connecting one part of the group to the rest. An arrow could be added to the bottom-right part, the cell would be `A+*` or `A*+`.
* The group `C` which is mirrored on one axis and thus has one connection line (the `+` and `-` can be switched around in this case)
* The group `B` with a completely unnecessary connection.

```tex
\startkarnaugh[ny=8, nx=8]
	\startkarnaughgroups
		,	,	,	,	,	,	,	,
		,	A,	A-C,	C,	,	A-,	A,	,
		,	,	C+,	C,	,	,	,	,
		B+,	,	,	,	,	,	,	B-,
		B,	,	,	,	,	,	,	B,
		,	,	C-,	C,	,	,	,	,
		,	A,	A-C,	C,	,	A+,	A,	,
		,	,	,	,	,	,	,	,
	\stopkarnaughgroups
\stopkarnaugh
```
