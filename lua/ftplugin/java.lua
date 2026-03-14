local config = {
	cmd = { "/opt/homebrew/bin/jdtls" },
	root_dir = vim.fs.dirname(vim.fs.find({ "pom.xml", "build.gradle", ".git" }, { upward = true })[1]),
}

require("jdtls").start_or_attach(config)
