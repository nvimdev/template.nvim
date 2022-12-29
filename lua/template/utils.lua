local utils = {}

function utils.input(input_text, default)
	input_text = input_text or ""
	default = default or ""
	local ok, input = pcall(vim.fn.inputdialog, input_text, default)
	if ok == nil then
		return false
	end
	if input == "Keyboard interrupt" then
		return false
	end
	return input
end

return utils
