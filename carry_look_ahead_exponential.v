/**
 ****************************************************************
 *	carry_look_ahead_exponential
 *
 * @details
 *	Calculate the whole carry_out for the next addition.
 *		op1 + op2 + cin
 *	where `op1`, `op2, and `cin` are `operand1`, `operand2`
 *	and `carry_in` in the actual module.
 *
 *	Additionally, the module will output the 'and' for two
 *	operands.
 *
 * @param [in] BIT_WIDTH
 *	The bit width of operands.
 *
 * @param [in] operand1
 *	The 1st operand.
 * @param [in] operand2
 *	The 2nd operand.
 * @param [in] carry_in
 *	The input carry.
 * @param [out] carry_out
 *	The output carry.
 * @param [out] and_result;
 *	The 'and' result of operands.
 *
 * @date
 *	2022/10/03
 * @authors
 *	RM
 ****************************************************************
 */

module carry_look_ahead_exponential #(
	parameter BIT_WIDTH = 4
) (
	operand1,
	operand2,
	carry_in,

	carry_out,
	and_result
);
	/* input/output */
	input [BIT_WIDTH - 1:0] operand1;
	input [BIT_WIDTH - 1:0] operand2;
	input carry_in;

	output [(BIT_WIDTH + 1) - 1:0] carry_out;
	output [BIT_WIDTH - 1:0] and_result;

	genvar i;

/**
 ****************************************************************
 * 1.	
 ****************************************************************
 */
	assign carry_out[0] = carry_in;
	generate
		for(i = 0; i < BIT_WIDTH; i = i + 1) begin
			carry_forecast #(
				.BIT_WIDTH(i + 1)
			) forecast (
				.operand1(operand1[i:0]),
				.operand2(operand2[i:0]),
				.carry_in(carry_in),

				.carry_out(carry_out[i + 1]),
				.and_result(and_result[i])
			);
		end
	endgenerate
endmodule