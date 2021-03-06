# ===========================================================================
#
# jugds.jl: Julia Interface to CoreArray Genomic Data Structure (GDS) Files
#
# Copyright (C) 2015-2020    Xiuwen Zheng
#
# This is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License Version 3 as
# published by the Free Software Foundation.
#
# jugds is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.	See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public
# License along with jugds.
# If not, see <http://www.gnu.org/licenses/>.


module jugds

import Base: joinpath, show, printstyled, println
import Printf: @sprintf
import DataStructures: OrderedDict

export type_gdsfile, type_gdsnode,
	gds_get_include,
	create_gds, open_gds, close_gds, sync_gds, cleanup_gds,
	root_gdsn, name_gdsn, rename_gdsn, ls_gdsn, index_gdsn, getfolder_gdsn,
	delete_gdsn, objdesp_gdsn, read_gdsn,
	put_attr_gdsn, get_attr_gdsn, delete_attr_gdsn



####  Open and initialize the CoreArray binary library  ####

@static if Sys.isapple()
	libfn = "libCoreArray.dylib"
elseif Sys.iswindows()
	libfn = "libCoreArray.dll"
elseif Sys.isunix()
	libfn = "libCoreArray.so"
else
	error("The platform is not supported.")
end

global libname = abspath(@__DIR__, "..", "deps", libfn)

if !isfile(libname)
	error("The CoreArray library cannot be found, please try Pkg.build(\"jugds\").")
end

const LibCoreArray = libname
global lib_c_api = C_NULL


# package initialization
function __init__()
	global lib_c_api = ccall((:GDS_Init, LibCoreArray), Ptr{Cvoid}, ())
end



# Get the directory of jugds *.h header files
"""
	gds_get_include()
Return the directory that contains the jugds *.h header files.
# Examples
```jldoctest
julia> gds_get_include()
```
"""
function gds_get_include()
	return joinpath(Pkg.dir(), "jugds", "deps", "include")
end



####  Type of GDS File and Node	 ####

struct type_gdsfile
	filename::String  # file name
	id::Int32         # internal file index
	readonly::Bool    # read-only
end

struct type_gdsnode
	id::Int32         # internal index
	ptr::Ptr{Cvoid}    # internal validation pointer
end


# GDS variable information
struct type_infogdsn
	name::String
	fullname::String
	storage::String
	trait::String
	gds_type::String
	dim::Vector{Int64}
	encoder::String
	compress::String
	cpratio::Float64
	size::Int64
	good::Bool
	hidden::Bool
	message::String
end



####  Internal Functions  ####

function error_check()
	s = ccall((:GDS_Error, LibCoreArray), Ptr{UInt8}, ())
	if s != C_NULL
		error(unsafe_string(s))
	end
	nothing
end




####  GDS File  ####

# Create a GDS file
"""
	create_gds(filename, allow_dup)
Create a new CoreArray Genomic Data Structure (GDS) file.
# Arguments
* `filename::String`: the file name of a new GDS file to be created
* `allow_dup::Bool=false`: if true, it is allowed to open a GDS file with read-only mode when it has been opened in the same session
# Examples
"""
function create_gds(filename::String, allow_dup::Bool=false)
	id = ccall((:gdsCreateGDS, LibCoreArray), Cint, (Cstring,Bool),
		filename, allow_dup)
	return type_gdsfile(filename, id, false)
end


# Open an existing GDS file
"""
	open_gds(filename, readonly, allow_dup)
Open an existing file of CoreArray Genomic Data Structure (GDS) for reading or writing.
# Arguments
* `filename::String`: the file name of a new GDS file to be created
* `readonly::Bool=true`: if true, the file is opened read-only; otherwise, it is allowed to write data to the file
* `allow_dup::Bool=false`: if true, it is allowed to open a GDS file with read-only mode when it has been opened in the same session
# Examples
```julia
fn = joinpath(Pkg.dir(), "jugds", "demo", "data", "ceu_exon.gds")
f = open_gds(fn)
f
close_gds(f)
```
"""
function open_gds(filename::String, readonly::Bool=true, allow_dup::Bool=false)
	id = ccall((:gdsOpenGDS, LibCoreArray), Cint, (Cstring, Bool, Bool),
		filename, readonly, allow_dup)
	return type_gdsfile(filename, id, readonly)
end


# Close the GDS file
"""
	close_gds(file)
Close a CoreArray Genomic Data Structure (GDS) file.
# Arguments
* `file::type_gdsfile`: an instance of `type_gdsfile`
"""
function close_gds(file::type_gdsfile)
	ccall((:gdsCloseGDS, LibCoreArray), Cvoid, (Cint,), file.id)
	file.filename = ""
	file.id = -1
	file.readonly = true
	return nothing
end


# Synchronize the GDS file
function sync_gds(file::type_gdsfile)
	ccall((:gdsSyncGDS, LibCoreArray), Cvoid, (Cint,), file.id)
	return nothing
end


# Clean up fragments of a GDS file
function cleanup_gds(filename::String, verbose::Bool=true)
	id = ccall((:gdsTidyUp, LibCoreArray), Cint, (Cstring, Bool),
		filename, verbose)
	return nothing
end



####  GDS Node  ####

# Get the root of GDS file
function root_gdsn(file::type_gdsfile)
	p = Ref{Ptr{Cvoid}}(C_NULL)
	id = ccall((:gdsRoot, LibCoreArray), Cint, (Cint, Ref{Ptr{Cvoid}}),
		file.id, p)
	return type_gdsnode(id, p[])
end


# Get the name(s) of child node
function ls_gdsn(obj::Union{type_gdsfile, type_gdsnode}, inc_hidden::Bool=false)
	if isa(obj, type_gdsfile)
		obj = root_gdsn(obj)
	end
	return ccall((:gdsnListName, LibCoreArray), Vector{String},
		(Cint, Ptr{Cvoid}, Bool), obj.id, obj.ptr, inc_hidden)
end


# Get a specified GDS node with path
function index_gdsn(obj::Union{type_gdsfile, type_gdsnode}, path::String,
		silent::Bool=false)
	if isa(obj, type_gdsfile)
		obj = root_gdsn(obj)
	end
	p = Ref{Ptr{Cvoid}}(C_NULL)
	id = ccall((:gdsnIndex, LibCoreArray), Cint,
		(Cint, Ptr{Cvoid}, Cstring, Bool, Ref{Ptr{Cvoid}}),
		obj.id, obj.ptr, path, silent, p)
	if p[] != C_NULL
		return type_gdsnode(id, p[])
	else
		return nothing
	end
end


# Get the name of GDS node
function name_gdsn(obj::type_gdsnode, full::Bool=false)
	s = ccall((:gdsnName, LibCoreArray), Ptr{Cvoid}, (Cint, Ptr{Cvoid}, Bool),
		obj.id, obj.ptr, full)
	return unsafe_pointer_to_objref(s)
end


# Rename the GDS node
function rename_gdsn(obj::type_gdsnode, newname::String)
	ccall((:gdsnRename, LibCoreArray), Cvoid,
		(Cint, Ptr{Cvoid}, Cstring), obj.id, obj.ptr, newname)
	return obj
end


# Get the descritpion of a specified node
function objdesp_gdsn(obj::type_gdsnode)
	dm = Int64[]
	cratio = Ref{Float64}(NaN)
	size = Ref{Int64}(-1)
	good = Ref{Bool}(false)
	hidden = Ref{Bool}(false)
	s = ccall((:gdsnDesp, LibCoreArray), Vector{String},
		(Cint, Ptr{Cvoid}, Vector{Int64}, Ref{Float64}, Ref{Int64}, Ref{Bool}, Ref{Bool}),
		obj.id, obj.ptr, dm, cratio, size, good, hidden)
	return type_infogdsn(s[1], s[2], s[3], s[4], s[5],
		dm, s[6], s[7], cratio[], size[], good[], hidden[], s[8])
end


# Get the descritpion of a specified node
function read_gdsn(obj::type_gdsnode, start::Vector{Int64}=Vector{Int64}(),
		count::Vector{Int64}=Vector{Int64}(), cvt::String="")
	p = ccall((:gdsnRead, LibCoreArray), Ptr{Cvoid},
		(Cint, Ptr{Cvoid}, Vector{Int64}, Vector{Int64}, Cstring),
		obj.id, obj.ptr, start, count, cvt)
	return unsafe_pointer_to_objref(p)
end



####  GDS Attributes  ####

# Add an attribute to a GDS node
function put_attr_gdsn(obj::type_gdsnode, name::String, val)
	return nothing
end


# Get the attributes of a GDS node
function get_attr_gdsn(obj::type_gdsnode)
	s = ccall((:gdsnGetAttrName, LibCoreArray), Ptr{Cvoid}, (Cint, Ptr{Cvoid}),
		obj.id, obj.ptr)
	nm = unsafe_pointer_to_objref(s)
	dict = OrderedDict{String, Any}()
	for i = 1:length(nm)
		p = ccall((:gdsnGetAttrIdx, LibCoreArray), Ptr{Cvoid}, (Cint, Ptr{Cvoid}, Cint),
			obj.id, obj.ptr, i)
		dict[nm[i]] = unsafe_pointer_to_objref(p)
	end
	return dict
end

# Remove an attribute from a GDS node
function delete_attr_gdsn(obj::type_gdsnode, name::String)
	ccall((:GDS_DeleteAttr, LibCoreArray), Cvoid,
		(Cint, Ptr{Cvoid}, Cstring), obj.id, obj.ptr, name)
	error_check()
	return nothing
end






####  Data Operations  ####






####  Display  ####

function size_fmt(size::Int64)
	if size >= 1000^4
		return @sprintf("%.1fT", size/(1000.0^4))
	elseif size >= 1000^3
		return @sprintf("%.1fG", size/(1000.0^3))
	elseif size >= 1000^2
		return @sprintf("%.1fM", size/(1000.0^2))
	elseif size >= 1000
		return @sprintf("%.1fK", size/1000.0)
	else
		return @sprintf("%dB", size)
	end
end

function enum_node(io::IO, obj::type_gdsnode, prefix::String,
		fullname::Bool, last::Bool, all::Bool, attr::Bool, expand::Bool)
	d = objdesp_gdsn(obj)
	if d.gds_type == "Label"
		lText = " "; rText = " "
	elseif d.gds_type == "VFolder"
		if d.good
			lText = "[ -->"; rText = "]"
		else
			lText = "[ -X-"; rText = "]"; expand = false
		end
	elseif d.gds_type == "Folder"
		lText = "["; rText = "]"
	elseif d.gds_type == "Unknown"
		lText = "   -X-"; rText = ""; expand = false
	else
		lText = "{"; rText = "}"
	end

	s = prefix * "+ " * name_gdsn(obj, fullname) * "   " * lText * " " * d.trait

	# if logical, factor, list, or data.frame
	if d.gds_type == "Logical"
		s = s * ",logical"
	elseif d.gds_type == "Factor"
		s = s * ",factor"
	end

	# show the dimension
	if length(d.dim) > 0
		s = s * " " * join(d.dim, "x")
	end

	# show compression
	if d.encoder != ""
		if attr
			s = s * " " * d.compress
		else
			s = s * " " * d.encoder
		end
	end

	if isfinite(d.cpratio)
		if d.cpratio >= 0.10
			s = s * @sprintf("(%0.1f%%)", 100*d.cpratio)
		else
			s = s * @sprintf("(%0.2f%%)", 100*d.cpratio)
		end
	end

	if d.size >= 0
		s = s * ", " * size_fmt(d.size)
	end

	s = s * " " * rText

	# attributes
	at = get_attr_gdsn(obj)
	if length(at) > 0
		s = s * " *"
	end

	print(io, s)
	if attr & length(at) > 0
		print(io, "< ")
		for i in 1:length(at)
			print(io, at.keys[1], ": ", at.vals[1])
			if i < length(at)
				print(io, "; ")
			end
		end
	end
	println(io)

	if expand && d.gds_type=="Folder"
		nm = ls_gdsn(obj, all)
		for i = 1:length(nm)
			n = length(prefix)
			if i < length(nm)
				if n >= 3
					if last
						s = prefix[1:end-3] * "   |--"
					else
						s = prefix[1:end-3] * "|  |--"
					end
				else
					s = "|--"
				end
			else
				if n >= 3
					if last
						s = prefix[1:end-3] * "   \\--"
					else
						s = prefix[1:end-3] * "|  \\--"
					end
				else
					s = "\\--"
				end
			end
			enum_node(io, index_gdsn(obj, nm[i]), s, false, i>=length(nm),
				all, attr, expand)
		end
	end

	return nothing
end


function show(io::IO, file::type_gdsfile; attr=false, all=false)
	size = ccall((:gdsFileSize, LibCoreArray), Clonglong, (Cint,), file.id)
	printstyled(io, "File:", color=:bold)
	printstyled(io, " ", file.filename, color=:bold)
	println(io, " (", size_fmt(size), ")")
	show(io, root_gdsn(file), attr=attr, all=all)
end


function show(io::IO, obj::type_gdsnode; attr=false, all=false, expand=true)
	printstyled(io, "", color=:bold)
	enum_node(io, obj, "", true, false, all, attr, expand)
end

end
