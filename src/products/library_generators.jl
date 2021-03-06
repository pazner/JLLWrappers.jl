
function declare_old_library_product(product_name, product_soname)
    return esc(quote

    end)
end

function declare_new_library_product(product_name)
    handle_name = Symbol(string(product_name, "_handle"))
    get_path_name = Symbol(string("get_", product_name, "_path"))
    path_name = Symbol(string(product_name, "_path"))
end

macro declare_library_product(product_name, product_soname)
    handle_name = Symbol(string(product_name, "_handle"))
    get_path_name = Symbol(string("get_", product_name, "_path"))
    path_name = Symbol(string(product_name, "_path"))
    @static if VERSION < v"1.6.0-DEV"
        lib_declaration = quote
            # On Julia 1.5-, this must be `const` and must be the SONAME
            const $(product_name) = $(product_soname)
        end
    else
        lib_declaration = quote
            # On Julia 1.6+, this doesn't have to be `const`!  Thanks Jeff!
            $(product_name) = ""
        end
    end
    
    return excat(
        quote
            # These will be filled in by init_library_product()
            $(handle_name) = C_NULL
            $(path_name) = ""
            function $(get_path_name)()
                return $(path_name)::String
            end
        end,
        lib_declaration,
    )
end

function init_new_library_product(product_name)
    @static if VERSION < v"1.6.0-DEV"
        return nothing
    else
        return quote
            # Initialize non-const variable export with the path to this product
            global $(product_name) = $(Symbol(string(product_name, "_path")))
        end
    end
end

macro init_library_product(product_name, product_path, dlopen_flags)
    handle_name = Symbol(string(product_name, "_handle"))
    path_name = Symbol(string(product_name, "_path"))
    return excat(quote
            global $(path_name) = joinpath(artifact_dir, $(product_path))
            # Manually `dlopen()` this right now so that future invocations
            # of `ccall` with its path/SONAME will find this path immediately.
            global $(handle_name) = dlopen($(path_name), $(dlopen_flags))
            push!(LIBPATH_list, joinpath(artifact_dir, $(dirname(product_path))))
        end,
        init_new_library_product(product_name),
    )
end
