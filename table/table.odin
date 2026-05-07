package table

import "../types"
import "core:fmt"
import "core:strings"
import "core:os/os2"

LITERAL_NEWLINE :: '\n'
LITERAL_WHITESPACE :: ' '
LITERAL_COMMA :: ','
STRING_LITERAL_COMMA :: ","
STRING_LITERAL_WHITESPACE :: " "

create :: proc (unparsed_csv_data: string) -> (parsed_data: []string, number_of_rows: int, number_of_columns: int) {
	lines, error_allocation := strings.split_lines(unparsed_csv_data)
	defer delete(lines)

	if nil != error_allocation {
		fmt.printfln("ERROR\n TYPE: ALLOCATION\n REASON: %v", error_allocation)
		os2.exit(1)
	}

	// Since this uses a 1D array rather than a 2D array,
	// this tells you when to enter the next colum
	number_of_columns = count_number_of_columns(lines[0])
	number_of_rows = len(lines)
	parsed_data = parse_csv_lines(&lines, number_of_rows, number_of_columns)

	return
}

parse_csv_lines :: proc (csv_lines: ^[]string, number_of_rows, number_of_columns: int) -> []string {
	array_length := number_of_columns * number_of_rows
	parsed_data := make([]string, array_length)

	// You want each cell to begin and end with one whitespace rune, so you must
	// build that. You cannot inline concatenate strings in Odin using "+"
	data_cell_builder := strings.builder_make()
	defer strings.builder_destroy(&data_cell_builder)

	parsed_data_index := 0
	for csv_line in csv_lines {
		csv_values, error_splitting_string := strings.split(csv_line, STRING_LITERAL_COMMA)
		defer delete(csv_values)

		if nil != error_splitting_string {
			fmt.printfln("ERROR\n TYPE: STRING MANIPULATION - SPLITTING\n REASON: %#v", error_splitting_string)
			continue
		}

		for value_position := 0; value_position < len(csv_values); value_position += 1 {
			strings.write_rune  (&data_cell_builder, LITERAL_WHITESPACE)
			strings.write_string(&data_cell_builder, csv_values[value_position])
			strings.write_rune  (&data_cell_builder, LITERAL_WHITESPACE)

			// Clone the result of to_string to "own" the string, and because string
			// builder re-uses the backing buffer. Clearing it resets length, so you
			// will trample your own data if you don't clone.
			parsed_data[parsed_data_index] = strings.clone(strings.to_string(data_cell_builder))

			strings.builder_reset(&data_cell_builder)
			parsed_data_index += 1
		}
	}

	return parsed_data
}

draw_table :: proc (parsed_data: []string, number_of_rows, number_of_columns: int,
args: types.ProgramArgs) -> string {

	per_table_count_corners :: 4
	per_table_count_decoration_lines :: 3 // North border + south border + table column footer
	per_table_count_column_footer_intersections :: 2
	per_table_count_newline := per_table_count_decoration_lines + number_of_rows
	per_row_delimiters_vertical := number_of_columns + 1
	per_table_count_vertical_delimiters := (1 + number_of_columns) * number_of_rows
	size_widest_data_cell := get_max_column_width(parsed_data)

	per_row_number_of_data_cell_runes := number_of_columns * size_widest_data_cell
	per_row_total_number_of_runes := per_row_delimiters_vertical + per_row_number_of_data_cell_runes

	//
	// Horizontal border data cells all use the same rune the same number of times (size_widest_data_cell)
	// so convert that into a reusable string
	//
	horizontal_line_builder := strings.builder_make()
	defer strings.builder_destroy(&horizontal_line_builder)
	for column_position := 0; column_position < number_of_columns; column_position += 1 {

		for fill_position := 0; fill_position < size_widest_data_cell; fill_position += 1 {
			strings.write_rune(&horizontal_line_builder, args.table_runes.horizontal)
		}

		// Where | would normally be, put a horizontal rune
		if column_position <= number_of_columns - 2 {
			// strings.write_rune(&horizontal_line_builder, '|')
			strings.write_rune(&horizontal_line_builder, args.table_runes.horizontal)
		}
	}
	table_horizontal_line_without_corners := strings.to_string(horizontal_line_builder)

	per_table_count_horizontal_lines := per_table_count_decoration_lines * (strings.rune_count(table_horizontal_line_without_corners))
	per_table_sum_of_data_cell_sizes := number_of_rows * (size_widest_data_cell * number_of_columns)

	//
	// Calculate the total number of runes for the table
	//
	per_table_expected_size := per_table_count_newline +
	per_table_count_corners +
	per_table_count_vertical_delimiters +
	per_table_count_column_footer_intersections +
	per_table_sum_of_data_cell_sizes +
	per_table_count_horizontal_lines

	table := strings.builder_make(0,  per_table_expected_size)

	//
	// DRAW: table northern border
	//
	strings.write_rune(&table, args.table_runes.corner_north_west)
	strings.write_string(&table, table_horizontal_line_without_corners)
	strings.write_rune(&table, args.table_runes.corner_north_east)
	strings.write_byte(&table, LITERAL_NEWLINE)

	//
	// DRAW: column headers
	//
	strings.write_rune(&table, args.table_runes.vertical)
	for column_header_position := 0; column_header_position < number_of_columns; column_header_position += 1 {
		column_header := parsed_data[column_header_position]

		number_of_spaces := size_widest_data_cell - strings.rune_count(column_header)

		strings.write_string(&table, column_header)
		whitespace := strings.repeat(STRING_LITERAL_WHITESPACE, number_of_spaces)
		strings.write_string(&table, whitespace)

		strings.write_rune(&table, args.table_runes.vertical)
	}
	strings.write_byte(&table, LITERAL_NEWLINE)


	//
	// DRAW: column footer row
	//
	if args.should_decorate_table_footer_row {
		strings.write_rune(&table, args.table_runes.column_footer_three_way_intersection_west)
		strings.write_string(&table, table_horizontal_line_without_corners)
		strings.write_rune(&table, args.table_runes.column_footer_three_way_intersection_east)
		strings.write_byte(&table, LITERAL_NEWLINE)
	}

	//
	// DRAW: table body content
	//
	column_counter := 0
	for parsed_data_count := number_of_columns; parsed_data_count < len(parsed_data); parsed_data_count += 1 {
		data_cell_element := parsed_data[parsed_data_count]

		is_last_element_and_should_print_newline := column_counter == number_of_columns
		if is_last_element_and_should_print_newline {
			column_counter = 0
			strings.write_byte(&table, LITERAL_NEWLINE)
		}

		is_first_element_in_row := 0 == column_counter
		if is_first_element_in_row {
			strings.write_rune(&table, args.table_runes.vertical)
		}

		runes_in_data_cell_element := strings.rune_count(data_cell_element)
		number_of_trailing_spaces := size_widest_data_cell - runes_in_data_cell_element
		if 0 == number_of_trailing_spaces {
			number_of_trailing_spaces = 0
		}

		strings.write_string(&table, data_cell_element)
		whitespace_padding := strings.repeat(STRING_LITERAL_WHITESPACE, number_of_trailing_spaces)
		strings.write_string(&table, whitespace_padding)

		strings.write_rune(&table, args.table_runes.vertical)

		column_counter += 1
	}

	strings.write_byte(&table, LITERAL_NEWLINE)

	//
	// DRAW: table southern border
	//
	strings.write_rune(&table, args.table_runes.corner_south_west)
	strings.write_string(&table, table_horizontal_line_without_corners)
	strings.write_rune(&table, args.table_runes.corner_south_east)
	strings.write_byte(&table, LITERAL_NEWLINE)

	return strings.to_string(table)
}

count_number_of_columns :: proc (row: string) -> int {
	number_of_commas := 0

	for item_in_row in row {
		if LITERAL_COMMA == item_in_row {
			number_of_commas += 1
		}
	}

	// There's always one more column than there are commas
	// because lines don't end with commas
	return number_of_commas + 1
}

get_max_column_width :: proc (data: []string) -> int {
	current_max_width := 0

	for data_element in data {
		number_of_runes := strings.rune_count(data_element)

		if number_of_runes > current_max_width {
			current_max_width = number_of_runes
		}
	}

	return current_max_width
}