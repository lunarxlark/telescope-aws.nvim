local aws_builtin = require("telescope._extensions.aws_builtin")

return require("telescope").register_extension({
	exports = {
		ec2 = aws_builtin.ec2,
	},
})
