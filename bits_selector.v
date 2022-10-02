/**
 ****************************************************************
 *	bits_selector
 *
 * @details
 *
 * @param [in] source
 *	The source of input bits.
 * @param [in] offset
 *	The offset to refer.
 * @param [in] otherwise_below
 *	The bit to be output when the offset is below the range.
 * @param [in] otherwise_above,
 *	The bit to be output when the offset is above the range.
 * @param [out] destination
 *	The destination of output bits.
 *
 * @date
 *	2022/09/30
 * @authors
 *	RM
 ****************************************************************
 */

module bits_selector #(
	parameter SOURCE_BIT_WIDTH = 32,
	parameter OFFSET_BIT_WIDTH = $clog2(SOURCE_BIT_WIDTH) + 1,
	parameter DESTINATION_BIT_WIDTH = 8,
	parameter BASE_SHIFT = 0
) (
	input [SOURCE_BIT_WIDTH - 1:0] source,
	input [OFFSET_BIT_WIDTH - 1:0] offset,
	input otherwise_below,
	input otherwise_above,

	output [DESTINATION_BIT_WIDTH - 1:0] destination
);
	genvar i;

	function destination_function (
		input [SOURCE_BIT_WIDTH - 1:0] source,
		input [OFFSET_BIT_WIDTH - 1:0] offset,
		input integer base
	);
		integer shifted_offset;
	begin
		shifted_offset = $signed(offset) + (base + BASE_SHIFT);

		if(shifted_offset < 0) begin
			destination_function = otherwise_below;
		end else if(shifted_offset >= SOURCE_BIT_WIDTH) begin
			destination_function = otherwise_above;
		end else begin
			destination_function = source[shifted_offset];
		end
	end
	endfunction

	generate
		for(i = 0; i < DESTINATION_BIT_WIDTH; i = i + 1) begin
			assign destination[i] =
				destination_function(
					source,
					offset,
					i
				);
		end
	endgenerate
endmodule