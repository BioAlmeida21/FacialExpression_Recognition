function process_txt(filepath)
   
	a=readdlm("../data/Annotations/"*filepath*".fqrs.txt")
	z(x) = x<num_sample
	idx=broadcast(z,a)
	a=a[idx]

	return a
end
