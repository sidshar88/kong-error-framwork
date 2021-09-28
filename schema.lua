local strings_array_error_record = {
    {
        values = {
            required = false,
            type = "string",
            match = "^[^_]+_.*[^,]+,.*$"
        }
    }
}

local strings_array_targeterror_record = {
    {
        values = {
            required = false,
            type = "string",
            match = "^[^_]+_.*[^,]+,.*$"
        }
    }
}

return{
    name = "error-framework",
    fields = {
        config = {
            type = "record",
            fields = {
                {
                    error = strings_array_error_record
                },
                {
                    targeterror = strings_array_targeterror_record
                },
            }
        },
    },
}