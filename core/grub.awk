# genkernel-modular/core/grub.awk
# -- Core awk script to handle grub.conf manipulation

# Copyright: 2006 plasmaroo@gentoo,org, rocket@gentoo.org
# License: GPLv2

BEGIN { RS="\n"; FS=""; OFS=""; ORS=""; state="0"; }
{
# State 0 = Just starting out
# State 1 = found the first title
# State 2 = found the next title

if(state == "0")
{
	if (match($0, /^title=/) || match($0, /^title */))
	{
		# Change state as we are going to generate a new title
		state = "1";
		next;
	} else {
		# Fill the header
		header = header $0 "\n";
	}
}

if(state == "1")
{
	if(match($0, /^[[:space:]]*kernel /))
	{
		# Found the first kernel line
		have_k = "1";
		my_kernel = $0 "\n";

		# Change the kernel string to the new info from the passed variables
		sub(/kernel-[[:alnum:][:punct:]]+/, "kernel-" KV, my_kernel);
	
	} else {
		if(match($0, /^[[:space:]]*initrd /))
		{
			# Found the first initrd/initramfs line
			# Copy the comment look ahead into the initrd/initramfs prefix
			# This is to preserve comments

			init_comments = init_comments commentLookahead;
			have_i = "1";			
			my_initrd = $0 "\n";
			
			# Change the initrd string to the new info
			sub(/initr(d|amfs)-[[:alnum:][:punct:]]+/, "init" TYPE "-" KV, my_initrd);

		} else {
			if($0 == "\n")
			{
				# We have matched a blank line; skip it and move along
				next;
			}
			if(match($0, /^[[:space:]]*#/))
			{
				# This is to catch comments and white space .. 
				
				if(commentLookahead)
					# Append to the already existing comments
					commentLookahead = commentLookahead $0 "\n";
				else
					# Store the first comment entry
					commentLookahead = $0 "\n" ;

				# No further processing of this line is necessary
				next;
			}

			# Not a title, comment, kernel or initrd
			if(!(match($0, /^title=/) || match($0, /^title */) ))
			{	
				commentLookahead = "";

				# We havent found a kernel yet, but we have comments
				# must be comments for the kernel soon to show up
				if(have_k != "1")
					{
						kernel_comments = kernel_comments commentLookahead $0 "\n";
					}
				else
				{
					# We haven't found a initrd line yet, but we have comments
					if(have_i != "1")
					{
						initrd_comments = initrd_comments commentLookahead $0 "\n";
					}
					# We haven't found a initrd, but we have comments
					# We know these are for the next entry or the footer of the file
					else
					{
						extra_comments = extra_comments commentLookahead $0 "\n";
					}
				}
			}
		}
	}

	if(have_k == "1" && ((match($0, /^title=/) || match($0, /^title */)) || NR == LIMIT))
	{
		state = "2";

		# Print any existing header
		if(header)
			print header; 

		# New title line
		print "title=Gentoo Linux (" KV ")\n";
		
		# Any spaces or comments before the kernel entry
		if(kernel_comments)
			print kernel_comments;
		print my_kernel;
		
		# Print the initrd lines if we built an separate/external initrd
		if (INITRAMFS_PRESENT == 0)
		{
			if (have_i != "1")
				 my_initrd="initrd /init" TYPE "-" KV "\n"

			# If we have initrd_comments and an initrd was found print them
			if(initrd_comments && have_i == "1")
				print initrd_comments;
			
			print my_initrd;
		}

		# No initrd found but we have comments so they must go on the next entry
		if(initrd_comments && have_i != "1")
			print initrd_comments;
		
		# An initrd must have been detected but there are still additional comments,
		# these go on the next entry
		if(extra_comments)
			print extra_comments;
		
		print $0 "\n";
		next;
	}
}

# Print the rest of the file
if(state == "2")
	print $0 "\n";
}
