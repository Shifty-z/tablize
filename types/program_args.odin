package types

ProgramArgs :: struct {
	// Whether there should be a horizontal decorator beneath all column headers.
	should_decorate_table_footer_row: bool,

	// Whether the maximum width should be table-wide or per-column.
	should_use_column_relative_maximum_widths: bool,


	table_runes: TableDrawingRunes,
}

TableDrawingRunes :: struct {
	// When a vertical border is drawn, what symbol is used?
	vertical: rune,

	// When a horizontal border is drawn, what symbol is used?
	horizontal: rune,

	// When drawing a border directly beneath column headers, this symbol is used
	column_header_border_south: rune,

	// When drawing the western three way intersection rune in the column footer row, this will be used
	column_footer_three_way_intersection_west: rune,

	// When drawing the eastern three way intersection rune in the column footer row, this will be used
	column_footer_three_way_intersection_east: rune,

	// The rune used to draw corners
	corner_north_west:rune,
	corner_north_east:rune,
	corner_south_west:rune,
	corner_south_east:rune,
}