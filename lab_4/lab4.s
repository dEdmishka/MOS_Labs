.data
format_record:
	.string	"%s %*s %*s %*s %s"
format_output:
	.string	"%s - %d - %.0f%%\n"
regex_pattern:
	.string	"^[^ ]* - - .*\" 3[0-9][0-9] "
usage_message:
	.string	"Usage: %s <log_file>\n"
open_error:
	.string	"Error opening file"

open_mode:
	.string	"r"
pipe_com:
	.string	"pipe"
fork_com:
	.string	"fork"
grep_com:
	.string	"grep"
execlp_com:
	.string	"execlp"
fdopen_com:
	.string	"fdopen"
realloc_com:
	.string	"realloc"

.text
.globl main

main:
	pushq	%rbp
	movq	%rsp, %rbp
	subq	$1664, %rsp
	movl	%edi, -1652(%rbp)
	movq	%rsi, -1664(%rbp)
	cmpl	$2, -1652(%rbp)
	je	check_input_args
	movq	-1664(%rbp), %rax
	movq	(%rax), %rdx
	movq	stderr(%rip), %rax
	leaq	usage_message(%rip), %rsi
	movq	%rax, %rdi
	movl	$0, %eax
	call	fprintf
	movl	$1, %edi
	call	exit

parse_line:
	pushq	%rbp
	movq	%rsp, %rbp
	subq	$32, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	movq	%rdx, -24(%rbp)
	movq	-24(%rbp), %rcx
	movq	-16(%rbp), %rdx
	movq	-8(%rbp), %rax
	leaq	format_record(%rip), %rsi
	movq	%rax, %rdi
	movl	$0, %eax
	call	sscanf
	nop
	leave
	ret

check_input_args:
	movq	-1664(%rbp), %rax
	movq	8(%rax), %rax
	movq	%rax, -48(%rbp)
	movq	-48(%rbp), %rax
	leaq	open_mode(%rip), %rsi
	movq	%rax, %rdi
	call	fopen
	movq	%rax, -56(%rbp)
	cmpq	$0, -56(%rbp)
	jne	try_open_file
	leaq	open_error(%rip), %rdi
	call	perror
	movl	$1, %edi
	call	exit

try_open_file:
	leaq	-84(%rbp), %rax
	movq	%rax, %rdi
	call	pipe
	cmpl	$-1, %eax
	jne	create_pipe
	leaq	pipe_com(%rip), %rdi
	call	perror
	movl	$1, %edi
	call	exit

create_pipe:
	call	fork
	movl	%eax, -60(%rbp)
	cmpl	$-1, -60(%rbp)
	jne	fork_child_process
	leaq	fork_com(%rip), %rdi
	call	perror
	movl	$1, %edi
	call	exit

fork_child_process:
	cmpl	$0, -60(%rbp)
	jne	child_read_pipe
	movl	-84(%rbp), %eax
	movl	%eax, %edi
	call	close
	movl	-80(%rbp), %eax
	movl	$1, %esi
	movl	%eax, %edi
	call	dup2
	movl	-80(%rbp), %eax
	movl	%eax, %edi
	call	close
	movq	-48(%rbp), %rax
	movl	$0, %r8d
	movq	%rax, %rcx
	leaq	regex_pattern(%rip), %rdx
	leaq	grep_com(%rip), %rsi
	leaq	grep_com(%rip), %rdi
	movl	$0, %eax
	call	execlp
	leaq	execlp_com(%rip), %rdi
	call	perror
	movl	$1, %edi
	call	exit

child_read_pipe:
	movl	-80(%rbp), %eax
	movl	%eax, %edi
	call	close
	movl	-84(%rbp), %eax
	leaq	open_mode(%rip), %rsi
	movl	%eax, %edi
	call	fdopen
	movq	%rax, -72(%rbp)
	cmpq	$0, -72(%rbp)
	jne	parent_process_open
	leaq	fdopen_com(%rip), %rdi
	call	perror
	movl	$1, %edi
	call	exit

parent_process_open:
	movq	$0, -8(%rbp)
	movl	$0, -12(%rbp)
	movl	$0, -16(%rbp)
	movl	$0, -20(%rbp)
	jmp	init_loop_counters

init_loop_counters:
	movq	-72(%rbp), %rdx
	leaq	-1120(%rbp), %rax
	movl	$1024, %esi
	movq	%rax, %rdi
	call	fgets
	testq	%rax, %rax
	jne	read_each_line
	movq	-72(%rbp), %rax
	movq	%rax, %rdi
	call	fclose
	leaq	-92(%rbp), %rcx
	movl	-60(%rbp), %eax
	movl	$0, %edx
	movq	%rcx, %rsi
	movl	%eax, %edi
	call	waitpid
	movl	$0, -28(%rbp)
	jmp	wait_child_process_for_count

read_each_line:
	leaq	-88(%rbp), %rdx
	leaq	-1648(%rbp), %rcx
	leaq	-1120(%rbp), %rax
	movq	%rcx, %rsi
	movq	%rax, %rdi
	call	parse_line
	movl	$0, -24(%rbp)
	jmp	jump_to_parse_line_func

wait_child_process_for_count:
	movl	-12(%rbp), %eax
	subl	$1, %eax
	cmpl	%eax, -28(%rbp)
	jl	increment_percentage_counter
	movl	$0, -36(%rbp)
	jmp	check_percentage_calc

jump_to_parse_line_func:
	movl	-24(%rbp), %eax
	cmpl	-12(%rbp), %eax
	jl	calculate_unique_host

calculate_unique_host:
	movl	-24(%rbp), %eax
	movslq	%eax, %rdx
	movq	%rdx, %rax
	salq	$6, %rax
	addq	%rdx, %rax
	salq	$2, %rax
	movq	%rax, %rdx
	movq	-8(%rbp), %rax
	addq	%rdx, %rax
	movq	%rax, %rdx
	leaq	-1648(%rbp), %rax
	movq	%rax, %rsi
	movq	%rdx, %rdi
	call	strcmp
	testl	%eax, %eax
	jne	check_line_format
	movl	-24(%rbp), %eax
	movslq	%eax, %rdx
	movq	%rdx, %rax
	salq	$6, %rax
	addq	%rdx, %rax
	salq	$2, %rax
	movq	%rax, %rdx
	movq	-8(%rbp), %rax
	addq	%rdx, %rax
	movl	256(%rax), %edx
	addl	$1, %edx
	movl	%edx, 256(%rax)
	jmp	increment_count_for_parsed_line

check_line_format:
	addl	$1, -24(%rbp)


increment_count_for_parsed_line:
	movl	-24(%rbp), %eax
	cmpl	-12(%rbp), %eax
	jne	check_all_lines_proceed
	movl	-12(%rbp), %eax
	addl	$1, %eax
	movslq	%eax, %rdx
	movq	%rdx, %rax
	salq	$6, %rax
	addq	%rdx, %rax
	salq	$2, %rax
	movq	%rax, %rdx
	movq	-8(%rbp), %rax
	movq	%rdx, %rsi
	movq	%rax, %rdi
	call	realloc
	movq	%rax, -8(%rbp)
	cmpq	$0, -8(%rbp)
	jne	realloc_memory
	leaq	realloc_com(%rip), %rdi
	call	perror
	movl	$1, %edi
	call	exit

realloc_memory:
	movl	-12(%rbp), %eax
	movslq	%eax, %rdx
	movq	%rdx, %rax
	salq	$6, %rax
	addq	%rdx, %rax
	salq	$2, %rax
	movq	%rax, %rdx
	movq	-8(%rbp), %rax
	addq	%rdx, %rax
	movq	%rax, %rdx
	leaq	-1648(%rbp), %rax
	movq	%rax, %rsi
	movq	%rdx, %rdi
	call	strcpy
	movl	-12(%rbp), %eax
	movslq	%eax, %rdx
	movq	%rdx, %rax
	salq	$6, %rax
	addq	%rdx, %rax
	salq	$2, %rax
	movq	%rax, %rdx
	movq	-8(%rbp), %rax
	addq	%rdx, %rax
	movl	$1, 256(%rax)
	addl	$1, -12(%rbp)

check_all_lines_proceed:
	addl	$1, -16(%rbp)

increment_percentage_counter:
	movl	-28(%rbp), %eax
	addl	$1, %eax
	movl	%eax, -32(%rbp)
	jmp	start_percentage_count

calculate_percentage:
	movl	-28(%rbp), %eax
	movslq	%eax, %rdx
	movq	%rdx, %rax
	salq	$6, %rax
	addq	%rdx, %rax
	salq	$2, %rax
	movq	%rax, %rdx
	movq	-8(%rbp), %rax
	addq	%rdx, %rax
	movl	256(%rax), %ecx
	movl	-32(%rbp), %eax
	movslq	%eax, %rdx
	movq	%rdx, %rax
	salq	$6, %rax
	addq	%rdx, %rax
	salq	$2, %rax
	movq	%rax, %rdx
	movq	-8(%rbp), %rax
	addq	%rdx, %rax
	movl	256(%rax), %eax
	cmpl	%eax, %ecx
	jge	update_counter
	movl	-28(%rbp), %eax
	movslq	%eax, %rdx
	movq	%rdx, %rax
	salq	$6, %rax
	addq	%rdx, %rax
	salq	$2, %rax
	movq	%rax, %rdx
	movq	-8(%rbp), %rax
	addq	%rax, %rdx
	leaq	-1392(%rbp), %rax
	movl	$32, %ecx
	movq	%rax, %rdi
	movq	%rdx, %rsi
	rep movsq
	movq	%rsi, %rdx
	movq	%rdi, %rax
	movl	(%rdx), %ecx
	movl	%ecx, (%rax)
	leaq	4(%rax), %rax
	leaq	4(%rdx), %rdx
	movl	-32(%rbp), %eax
	movslq	%eax, %rdx
	movq	%rdx, %rax
	salq	$6, %rax
	addq	%rdx, %rax
	salq	$2, %rax
	movq	%rax, %rdx
	movq	-8(%rbp), %rax
	leaq	(%rdx,%rax), %rcx
	movl	-28(%rbp), %eax
	movslq	%eax, %rdx
	movq	%rdx, %rax
	salq	$6, %rax
	addq	%rdx, %rax
	salq	$2, %rax
	movq	%rax, %rdx
	movq	-8(%rbp), %rax
	addq	%rdx, %rax
	movq	%rcx, %rdx
	movl	$260, %ecx
	movq	(%rdx), %rsi
	movq	%rsi, (%rax)
	movl	%ecx, %esi
	addq	%rax, %rsi
	leaq	8(%rsi), %rdi
	movl	%ecx, %esi
	addq	%rdx, %rsi
	addq	$8, %rsi
	movq	-16(%rsi), %rsi
	movq	%rsi, -16(%rdi)
	leaq	8(%rax), %rdi
	andq	$-8, %rdi
	subq	%rdi, %rax
	subq	%rax, %rdx
	addl	%eax, %ecx
	andl	$-8, %ecx
	movl	%ecx, %eax
	shrl	$3, %eax
	movl	%eax, %eax
	movq	%rdx, %rsi
	movq	%rax, %rcx
	rep movsq
	movl	-32(%rbp), %eax
	movslq	%eax, %rdx
	movq	%rdx, %rax
	salq	$6, %rax
	addq	%rdx, %rax
	salq	$2, %rax
	movq	%rax, %rdx
	movq	-8(%rbp), %rax
	addq	%rdx, %rax
	movq	%rax, %rdx
	leaq	-1392(%rbp), %rax
	movl	$260, %ecx
	movq	(%rax), %rsi
	movq	%rsi, (%rdx)
	movl	%ecx, %esi
	addq	%rdx, %rsi
	leaq	8(%rsi), %rdi
	movl	%ecx, %esi
	addq	%rax, %rsi
	addq	$8, %rsi
	movq	-16(%rsi), %rsi
	movq	%rsi, -16(%rdi)
	leaq	8(%rdx), %rdi
	andq	$-8, %rdi
	subq	%rdi, %rdx
	subq	%rdx, %rax
	addl	%edx, %ecx
	andl	$-8, %ecx
	shrl	$3, %ecx
	movl	%ecx, %edx
	movl	%edx, %edx
	movq	%rax, %rsi
	movq	%rdx, %rcx
	rep movsq

update_counter:
	addl	$1, -32(%rbp)

start_percentage_count:
	movl	-32(%rbp), %eax
	cmpl	-12(%rbp), %eax
	jl	calculate_percentage
	addl	$1, -28(%rbp)

count_redirects:
	movl	-36(%rbp), %eax
	movslq	%eax, %rdx
	movq	%rdx, %rax
	salq	$6, %rax
	addq	%rdx, %rax
	salq	$2, %rax
	movq	%rax, %rdx
	movq	-8(%rbp), %rax
	addq	%rdx, %rax
	movl	256(%rax), %eax
	addl	%eax, -20(%rbp)
	addl	$1, -36(%rbp)

check_percentage_calc:
	movl	-36(%rbp), %eax
	cmpl	-12(%rbp), %eax
	jge	handle_line
	cmpl	$9, -36(%rbp)
	jle	count_redirects

handle_line:
	movl	$0, -40(%rbp)
	jmp	check_proceeded_lines

print_output:
	movl	-40(%rbp), %eax
	movslq	%eax, %rdx
	movq	%rdx, %rax
	salq	$6, %rax
	addq	%rdx, %rax
	salq	$2, %rax
	movq	%rax, %rdx
	movq	-8(%rbp), %rax
	addq	%rdx, %rax
	movl	256(%rax), %eax
	imull	$100, %eax, %eax
	cltd
	idivl	-20(%rbp)
	cvtsi2ss	%eax, %xmm0
	movss	%xmm0, -76(%rbp)
	cvtss2sd	-76(%rbp), %xmm0
	movl	-40(%rbp), %eax
	movslq	%eax, %rdx
	movq	%rdx, %rax
	salq	$6, %rax
	addq	%rdx, %rax
	salq	$2, %rax
	movq	%rax, %rdx
	movq	-8(%rbp), %rax
	addq	%rdx, %rax
	movl	256(%rax), %ecx
	movl	-40(%rbp), %eax
	movslq	%eax, %rdx
	movq	%rdx, %rax
	salq	$6, %rax
	addq	%rdx, %rax
	salq	$2, %rax
	movq	%rax, %rdx
	movq	-8(%rbp), %rax
	addq	%rdx, %rax
	movl	%ecx, %edx
	movq	%rax, %rsi
	leaq	format_output(%rip), %rdi
	movl	$1, %eax
	call	printf
	addl	$1, -40(%rbp)

check_proceeded_lines:
	movl	-40(%rbp), %eax
	cmpl	-12(%rbp), %eax
	jge	free_line_mem
	cmpl	$9, -40(%rbp)
	jle	print_output

free_line_mem:
	movq	-8(%rbp), %rax
	movq	%rax, %rdi
	call	free
	movq	-56(%rbp), %rax
	movq	%rax, %rdi
	call	fclose
	movl	$0, %eax
	leave
	ret
