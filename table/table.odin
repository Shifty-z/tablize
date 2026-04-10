package table

import "../types"
import "core:fmt"
import "core:strings"
import "core:os/os2"

LITERAL_NEWLINE :: '\n'
LITERAL_WHITESPACE :: ' '
LITERAL_COMMA :: ','

create :: proc (unparsed_csv_data: string, args: types.ProgramArgs) -> (parsed_data: []string, number_of_rows: int, number_of_columns: int) {
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
	parsed_data = parse_csv_lines(&lines, number_of_columns, number_of_rows)

	return
}

parse_csv_lines :: proc (csv_lines: ^[]string, number_of_rows, number_of_columns: int) -> []string {
// You know how many rows and columns you have, so create a container
// already allocated with the correct size.
	array_length := number_of_columns * number_of_rows
	parsed_data := make([]string, array_length)

	parsed_data_index := 0
	for line in csv_lines {
		csv_header, error_splitting_string := strings.split(line, ",")
		defer delete(csv_header)

		if nil != error_splitting_string {
			fmt.printfln("ERROR\n TYPE: STRING MANIPULATION - SPLITTING\n REASON: %#v", error_splitting_string)
			continue
		}

		// This is equivalent to append(&parsed_data, ..results)
		index_increment := 0
		for ; index_increment < len(csv_header); index_increment += 1 {
			parsed_data[parsed_data_index + index_increment] = csv_header[index_increment]
		}

		parsed_data_index += index_increment
	}

	return parsed_data
}

draw_table :: proc (parsed_data: []string, number_of_rows, number_of_columns: int,
args: types.ProgramArgs) -> string {
// This is initialized as such because I want data cells to have
// at least one whitespace after their content. It's easier to read
	number_of_trailing_whitespace_runes_per_data_cell := 1

	// The widest any column will be is this.
	// You pad each data cell with leading whitespace, so you're wrong about the above 😂
	widest_column_size := get_max_col_width(parsed_data) +
	number_of_trailing_whitespace_runes_per_data_cell

	runes_per_row_without_decorations_or_space_offsets :=
	widest_column_size * number_of_columns

	// This is 2 because of some flags you removed
	number_of_border_decorations_per_row := 2

	// Each data cell starts with a leading whitespace for padding
	number_of_leading_whitespaces_per_row := number_of_columns - 1

	// Each data cell adds its own vertical delimiter, except for the last and first
	number_of_vertical_delimiters_per_row :=
	number_of_leading_whitespaces_per_row - number_of_border_decorations_per_row

	// The maximum number of characters any row will display
	// For example, the header, line beneath the header, and the table footer
	total_number_of_runes_per_row :=
	runes_per_row_without_decorations_or_space_offsets +
	number_of_border_decorations_per_row +
	number_of_vertical_delimiters_per_row +
	number_of_leading_whitespaces_per_row

	table := strings.builder_make(0, total_number_of_runes_per_row * number_of_rows)

	// DRAW: table's northern decorations
	table_border_north := decorate_table_line(
	total_number_of_runes_per_row,
	args.decorator_table_north_west_corner,
	args.decorator_horizontal,
	args.decorator_table_north_east_corner
	)

	strings.write_string(&table, table_border_north)
	strings.write_byte(&table, LITERAL_NEWLINE)

	// DRAW: column headers
	{
		for column_position := 0; column_position < number_of_columns; column_position += 1 {
			column_header := parsed_data[column_position]

			// First element should draw its left border and right border
			// every other element should just draw its right border
			is_first_element_in_row := 0 == column_position
			if is_first_element_in_row {
				strings.write_rune(&table, args.decorator_vertical)
			}

			// Can you use the uncommented out code you have
			// or do you need the 1 if (...) else (...) line?
			// You already calculate the widest column size, so
			// you shouldn't need the 1 if (...) else (...) code
			// widest_column_size - len(column_header)?
			// number_of_spaces := 1 if len(column_header) >= widest_column_size else widest_column_size - len(column_header)
			number_of_spaces := widest_column_size - len(column_header)

			strings.write_byte(&table, LITERAL_WHITESPACE) // Just padding
			strings.write_string(&table, column_header)
			whitespace := strings.repeat(" ", number_of_spaces)
			strings.write_string(&table, whitespace)

			strings.write_rune(&table, args.decorator_vertical)
		}

		strings.write_byte(&table, LITERAL_NEWLINE)
	}

	// DRAW: footer row
	if args.should_decorate_table_footer_row {
		table_footer_row := decorate_table_line(
		total_number_of_runes_per_row,
		'├',
		args.decorator_horizontal,
		'┤',
		)

		strings.write_string(&table, table_footer_row)
		strings.write_byte(&table, LITERAL_NEWLINE)
	}

	// TODO: Rename this to column_counter
	col_idx := 0
	for i := number_of_columns; i < len(parsed_data); i += 1 {
	// TODO: Rename this to data_cell_element
		element := parsed_data[i]

		should_print_on_newline := col_idx == number_of_columns
		if should_print_on_newline {
			col_idx = 0
			strings.write_byte(&table, LITERAL_NEWLINE)
		}

		is_first_element_in_row := 0 == col_idx
		if is_first_element_in_row {
			strings.write_rune(&table, args.decorator_vertical)
		}

		// TODO: Determine whether this is required. You already calculated
		// the widest possible column WITHOUT a trailing whitespace
		// so this should always be zero.
		number_of_spaces := 0 if len(element) >= widest_column_size else widest_column_size - len(element)

		strings.write_byte(&table, LITERAL_WHITESPACE) // Just padding
		strings.write_string(&table, element)
		whitespace := strings.repeat(" ", number_of_spaces)
		strings.write_string(&table, whitespace)

		strings.write_rune(&table, args.decorator_vertical)

		col_idx += 1
	}

	strings.write_byte(&table, LITERAL_NEWLINE)

	table_border_southern_line := decorate_table_line(
	total_number_of_runes_per_row,
	args.decorator_table_south_west_corner,
	args.decorator_horizontal,
	args.decorator_table_south_east_corner
	)
	strings.write_string(&table, table_border_southern_line)

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

get_max_col_width :: proc (data: []string) -> int {
	current_max_width := 0

	for data_element in data {
		number_of_runes := strings.rune_count(data_element)

		if number_of_runes > current_max_width {
			current_max_width = number_of_runes
		}
	}

	return current_max_width
}

decorate_table_line :: proc (total_length_of_row: int, decorator_start, decorator_middle, decorator_end: rune) -> string {
// TODO: Determine whether this should be initialized with
// total_length_of_row + 1 as the length
	decorator := strings.builder_make_len_cap(0, total_length_of_row)

	strings.write_rune(&decorator, decorator_start)

	// I think I'm adding one here because of the leading whitespace before
	// each table element
	fill_amount := total_length_of_row + 1
	for counter := 0; counter < fill_amount; counter += 1 {
		strings.write_rune(&decorator, decorator_middle)
	}

	strings.write_rune(&decorator, decorator_end)

	return strings.to_string(decorator)
}