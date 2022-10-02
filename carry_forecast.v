/**
 ****************************************************************
 *	carry_forecast
 *
 * @details
 *	Calculate the MSB of carry_out for the next addition.
 *		op1 + op2 + cin
 *	where `op1`, `op2, and `cin` are `operand1`, `operand2`
 *	and `carry_in` in the actual module.
 *
 *	Additionally, the module will output the 'and' for the
 *	MSB of two operands.
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
 *	The 'and' result of MSBs in operands.
 *
 * @date
 *	2022/10/03
 * @authors
 *	RM
 ****************************************************************
 */

module carry_forecast #(
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

	output carry_out;
	output and_result;

	/* module variabels */
	localparam NUMBER_OF_TERM = 2 ** (BIT_WIDTH + 1) - 1;
	wire [NUMBER_OF_TERM - 1:0] term;

	genvar i;

/**
 ****************************************************************
 * 1.	When the length of operands is 0, the forecast of carry
 *	is just `carry_in`. Starting from that, the number of the
 *	terms to be considered almost doubles every time the
 *	length of operands increases by one. We need to take
 *	'and' operation with previous terms and `operand1`, and
 *	do the same with previous terms and `operand2`. One
 *	another term to be considered is direct 'and' of
 *	`operand1` and `operand2` at the current position. So,
 *	you just need to take 'and' following the tree depicted
 *	below.
 *		       [MSB]        [MSB - 1]             [LSB + 1]        [LSB]      [CIN]
 *		-+->    op1    -+->    op1    -- ... -+->    op1    -+->    op1    ->  cin (*)
 *		 |              +->    op2    -- ...  |              +->    op2    ->  cin (*)
 *		 |              +-> op1 & op2 (*)     |              +-> op1 & op2 (*)
 *		 |                                    |
 *		 +->    op2    -+->    op1    -- ...  +->    op2    -+->    op1    ->  cin (*)
 *		 |              +->    op2    -- ...  |              +->    op2    ->  cin (*)
 *		 |              +-> op1 & op2 (*)     |              +-> op1 & op2 (*)
 *		 |                                    |
 *		 +-> op1 & op2 (*)                    +-> op1 & op2 (*)
 *	You find three nodes at branches. The star in the diagram
 *	(*) means that there are no more branches after that
 *	node. Here `op1` represents `operand1` and `op2`
 *	represents `operand2. Also `cin` is `carry_in` in the
 *	context.
 *
 *	Of course, again, the number of terms is only one if the
 *	length of operands is zero, and the term is `cin`. For
 *	another example, if the length of the operands is 2, the
 *	tree will look like
 *		       [1st]          [0th]      [CIN]
 *		-+->    op1    -+->    op1    ->  cin (*)
 *		 |              +->    op2    ->  cin (*)
 *		 |              +-> op1 & op2 (*)
 *		 |
 *		 +->    op2    -+->    op1    ->  cin (*)
 *		 |              +->    op2    ->  cin (*)
 *		 |              +-> op1 & op2 (*)
 *		 |
 *		 +-> op1 & op2 (*)
 *	This is the tree structure to be taken 'and' operation
 *	for `length = 2`. Following the tree, the 7 terms to be
 *	considered are enumerated as
 *		0: op1[1] & op1[0] & cin
 *		1: op1[1] & op2[0] & cin
 *		2: op1[1] & op1[0] & op2[0]
 *		3: op2[1] & op1[0] & cin
 *		4: op2[1] & op2[0] & cin
 *		5: op2[1] & op1[0] & op2[0]
 *		6: op1[2] & op[2]
 *	Therefore, the number of terms are calculated by a simple
 *	arithmetics.
 *		NUMBER_OF_TERM(0) = 1
 *		NUMBER_OF_TERM(1) = 2 * NUMBER_OF_TERM(0) + 1 = 3
 *		NUMBER_OF_TERM(2) = 2 * NUMBER_OF_TERM(1) + 1 = 7
 *		...
 *		NUMBER_OF_TERM(n) = 2 ^ (n + 1) - 1
 *	One notion here is that we can have an index for every
 *	term to be considered according to the 'and' tree
 *	representation.
 *
 *	The number of wires to be necessary to calculate one
 *	'and' component also differs for each index. You can
 *	determine the number by measuring the depth of the tree
 *	for each path. In order to calculate this, we adopt a
 *	representation that resembles arb-ary digits. In our case
 *	the radix of n-th bit is
 *		radix(n) = 2 ^ (n + 1) - 1
 *	and the radix starts from MSB, unlike normal radix
 *	starting from LSB. Also, the branch finished when we
 *	encounter an operation on `operand1` and `operand2` at
 *	the same bit position, so the kind of digits we want to
 *	get are the followings.
 *		  [2nd][1st][0th]      [2nd][1st][0th]      [2nd][1st][2th]
 *		0:  0,   0,   0      7:  1,   0,   0      7:  2,   *,   *
 *		1:  0,   0,   1      8:  1,   0,   1
 *		2:  0,   0,   2      9:  1,   0,   2
 *		3:  0,   1,   0     10:  1,   1,   0
 *		4:  0,   1,   1     11:  1,   1,   1
 *		5:  0,   1,   2     12:  1,   1,   2
 *		6:  0,   2,   *     13:  1,   2,   *
 *	Here, when the digit is 0 for a certain position, we take
 *	`operand1`, and when it is 1, we take `operand2. Finally,
 *	when we have got 2, it is the end and the digits after
 *	that are 'don't care'. Say, for index 7, the digits are
 *	`1, 0, 0`, so the operation is,
 *		op2[2] & op1[1] & op1[0] & cin
 *	Another example is for index 13, then the digits are
 *	`1, 2, *` with * representing 'don't care', so the target
 *	operation becomes
 *		op2[2] & op1[1] & op2[1]
 *	We are going to implement this.
 *
 *	As to calculating the number of atomic wires like
 *	`op2[2]`, `op1[1]` and `cin`, it is enough to count up by
 *	1 when the digit at a position is 0 or 1. And the
 *	calculation process ends and counts by 2 when we
 *	encounter 2.
 *
 *	We calculate the digits representation for each index and
 *	determine the length for atomic wires. We first
 *	declare wires to store. After that, we calculate the
 *	representation again. And along that representation, we
 *	assign atomic bits like `op2[2]`, `op1[1]` and `cin`.
 *	When these assignments are completed, do 'and' operation
 *	on all the atomics.
 ****************************************************************
 */
	function integer length_of_atomic_function(
		input integer number
	);
		integer i;
		integer flag;
		integer branch[BIT_WIDTH - 1:0];
		integer length;
	begin
		for(i = BIT_WIDTH - 1; i >= 0; i = i - 1) begin
			branch[i] = number / (2 ** (i + 1) - 1);
			number = number % (2 ** (i + 1) - 1);
		end

		length = 1;
		flag = 1;
		for(i = BIT_WIDTH - 1; flag && i >= 0; i = i - 1) begin
			length = length + 1;
			if(branch[i] == 2) begin
				flag = 0;
			end
		end

		length_of_atomic_function = length;
	end
	endfunction

	generate
		for(i = 0; i < NUMBER_OF_TERM; i = i + 1) begin
			localparam LENGTH_OF_ATOMIC = length_of_atomic_function(i);

			function term_function(
				input [BIT_WIDTH - 1:0] operand1,
				input [BIT_WIDTH - 1:0] operand2,
				input carry_in,
				input integer number
			);
				reg [LENGTH_OF_ATOMIC - 1:0] atomic;
				integer flag;
				integer i;
				integer branch[BIT_WIDTH - 1:0];
				integer length;
			begin
				for(i = 0; i < BIT_WIDTH; i = i + 1) begin
					branch[i] = number / (2 ** (BIT_WIDTH - i) - 1);
					number = number % (2 ** (BIT_WIDTH - i) - 1);
				end

				flag = 1;
				length = 0;
				for(i = 0; flag && i < BIT_WIDTH; i = i + 1) begin
					if(branch[i] == 2) begin
						atomic[length] =
							operand1[(BIT_WIDTH - 1) - i];
						length = length + 1;
						atomic[length] =
							operand2[(BIT_WIDTH - 1) - i];
						length = length + 1;

						flag = 0;
					end else begin
						if(branch[i] == 0) begin
							atomic[length] =
								operand1[(BIT_WIDTH - 1) - i];
							length = length + 1;
						end else begin
							atomic[length] =
								operand2[(BIT_WIDTH - 1) - i];
							length = length + 1;
						end

						if(i == BIT_WIDTH - 1) begin
							atomic[length] = carry_in;
							length = length + 1;
						end
					end
				end

				term_function = & atomic;
			end
			endfunction

			assign term[i] = term_function(
					operand1,
					operand2,
					carry_in,
					i
				);
		end
	endgenerate

/**
 ****************************************************************
 * 2.	Finally, after calculating every term to be considered,
 *	we take 'or' operation on them. Here we show that a case
 *	for `length = 2`. The result `carry_out` should be
 *		  (op1[1] & op1[0] & cin)
 *		| (op1[1] & op2[0] & cin)
 *		| (op1[1] & op1[0] & op2[0])
 *		| (op2[1] & op1[0] & cin)
 *		| (op2[1] & op2[0] & cin)
 *		| (op2[1] & op1[0] & op2[0])
 *		| (op1[2] & op[2])
 *
 *	In the calculation above, you might have noticed the last
 *	term is an 'and' of MSBs in operands.
 ****************************************************************
 */
	assign carry_out = | term;
	assign and_result = term[NUMBER_OF_TERM - 1];
endmodule