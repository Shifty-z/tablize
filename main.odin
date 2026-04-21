package main

import "table"
import "types"
import "core:os/os2"
import "core:flags"
import "core:fmt"

// See dbg.sh
TABLIZE_DBG :: #config(TABLIZE_DBG, false)

ProgramInput :: struct {
	file: string `"flags:"file" required usage:"A CSV file containing data presented in a table"`,
	simple_table: bool `usage:"When set to true, uses +, |, -, and = to draw the table"`
}

main :: proc() {
	command_line_flags := ProgramInput { }
	parse_err_command_line_flags := flags.parse(&command_line_flags, os2.args[1:])

	if nil != parse_err_command_line_flags {
		flags.print_errors(ProgramInput, parse_err_command_line_flags,
		"Tablize - Display CSV data in a table.", .Odin)
		os2.exit(1)
	}

	data, read_err := os2.read_entire_file(command_line_flags.file, context.allocator)
	if nil != read_err {
		fmt.printfln("ERROR\n TYPE: FILE I/O\n REASON: Unable to read file because %v", read_err)
		os2.exit(1)
	}

	// https://usgraphics.com/static/products/TX-02/datasheet/TX-02-datasheet.a43c0c7f8d8c.pdf
	// https://graphemica.com
	decorator_vertical := '│'
	decorator_horizontal := '─'
	decorator_column_header_border_south := '═'
	decorator_table_north_west_corner := '┌'
	decorator_table_north_east_corner := '┐'
	decorator_table_south_east_corner := '┘'
	decorator_table_south_west_corner := '└'
	decorator_table_three_way_intersection_west := '├'
	decorator_table_three_way_intersection_east := '┤'

	if command_line_flags.simple_table {
		decorator_vertical = '|'
		decorator_horizontal = '-'
		decorator_column_header_border_south = '='
		decorator_table_north_west_corner = '+'
		decorator_table_north_east_corner = '+'
		decorator_table_south_east_corner = '+'
		decorator_table_south_west_corner = '+'
		decorator_table_three_way_intersection_west = '+'
		decorator_table_three_way_intersection_east = '+'
	}

	table_glyphs := types.TableDrawingRunes {
		vertical = decorator_vertical,
		horizontal = decorator_horizontal,
		column_header_border_south = decorator_column_header_border_south,
		column_footer_three_way_intersection_west = decorator_table_three_way_intersection_west,
		column_footer_three_way_intersection_east = decorator_table_three_way_intersection_east,
		corner_north_west = decorator_table_north_west_corner,
		corner_north_east = decorator_table_north_east_corner,
		corner_south_west = decorator_table_south_west_corner,
		corner_south_east = decorator_table_south_east_corner,
	}

	args := types.ProgramArgs {
		should_decorate_table_footer_row  = true,
		decorator_vertical = decorator_vertical,
		decorator_horizontal = decorator_horizontal,
		decorator_column_header_border_south = decorator_column_header_border_south,
		decorator_table_north_west_corner = decorator_table_north_west_corner,
		decorator_table_north_east_corner = decorator_table_north_east_corner,
		decorator_table_south_east_corner = decorator_table_south_east_corner,
		decorator_table_south_west_corner = decorator_table_south_west_corner,
		decorator_table_three_way_intersection_west = decorator_table_three_way_intersection_west,
		decorator_table_three_way_intersection_east = decorator_table_three_way_intersection_east,
		should_use_column_relative_maximum_widths = true,
		table_runes = table_glyphs
	}

	when TABLIZE_DBG {
		empty_file_data, empty_file_read_err := os2.read_entire_file("empty_file.csv", context.allocator)
		if nil != empty_file_read_err {
			fmt.printfln("ERROR\n TYPE: FILE I/O\n REASON: Unable to read file because %v", empty_file_read_err)
			os2.exit(1)
		}

		one_col_no_data, one_col_no_data_read_err := os2.read_entire_file("one_column_no_data.csv", context.allocator)
		if nil != one_col_no_data_read_err {
			fmt.printfln("ERROR\n TYPE: FILE I/O\n REASON: Unable to read file because %v", one_col_no_data_read_err)
			os2.exit(1)
		}

		one_col_with_data, one_col_with_data_read_err := os2.read_entire_file("one_column_with_data.csv", context.allocator)
		if nil != one_col_with_data_read_err {
			fmt.printfln("ERROR\n TYPE: FILE I/O\n REASON: Unable to read file because %v", one_col_with_data_read_err)
			os2.exit(1)
		}

		two_col_with_data, two_col_with_data_read_err := os2.read_entire_file("two_columns_with_data.csv", context.allocator)
		if nil != two_col_with_data_read_err {
			fmt.printfln("ERROR\n TYPE: FILE I/O\n REASON: Unable to read file because %v", two_col_with_data_read_err)
			os2.exit(1)
		}

		two_rows_three_cols, two_rows_three_cols_read_err := os2.read_entire_file("2rows_3cols.csv", context.allocator)
		if nil != two_rows_three_cols_read_err {
			fmt.printfln("ERROR\n TYPE: FILE I/O\n REASON: Unable to read file because %v", two_rows_three_cols_read_err)
			os2.exit(1)
		}

		three_rows_two_cols_with_empty_cell, three_rows_two_cols_with_empty_cell_read_err :=
		os2.read_entire_file("3rows_2cols_with_empty_cell.csv", context.allocator)

		if nil != three_rows_two_cols_with_empty_cell_read_err {
			fmt.printfln("ERROR\n TYPE: FILE I/O\n REASON: Unable to read file because %v", three_rows_two_cols_with_empty_cell_read_err)
			os2.exit(1)
		}

		data_sources := [7][]byte{
			data,
			empty_file_data,
			one_col_no_data,
			one_col_with_data,
			two_col_with_data,
			two_rows_three_cols,
			three_rows_two_cols_with_empty_cell
		}

		for data_source in &data_sources {
			parsed_data, number_of_rows, number_of_columns := table.create(cast(string)data_source, args)
			printable_table := table.draw_table(parsed_data, number_of_rows, number_of_columns, args)
			fmt.println(printable_table)
		}
		return
	}

	parsed_data, number_of_rows, number_of_columns := table.create(cast(string)data, args)
	fmt.printfln("MAIN :: Number of rows: %d; Number of columns: %d", number_of_rows, number_of_columns)
	printable_table := table.draw_table(parsed_data, number_of_rows, number_of_columns, args)
	fmt.println(printable_table)
}