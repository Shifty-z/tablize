package types

ProgramArgs :: struct {
	should_decorate_table_footer_row: bool,    // Whether there should be a horizontal decorator beneath all column headers.
	decorator_vertical: rune,                  // When a vertical border is drawn, what symbol should be used?
	decorator_horizontal: rune,                // When a horizontal border is drawn, what symbol should be used?
	decorator_column_header_border_south: rune,// When drawing a border directly beneath the column headers, what symbol should be used?
	decorator_table_north_west_corner: rune,   // Rune used to draw this corner
	decorator_table_north_east_corner: rune,   // Rune used to draw this corner
	decorator_table_south_east_corner: rune,   // Rune used to draw this corner
	decorator_table_south_west_corner: rune,   // Rune used to draw this corner
	should_use_column_relative_maximum_widths: bool, // Whether the maximum width should be table-wide or per-column.
}