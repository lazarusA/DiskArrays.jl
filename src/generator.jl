
struct DiskGenerator{I,F}
    f::F
    iter::I
end
# Copied from `iterate(::Generator, s...) in julia 1.9
function Base.iterate(dg::DiskGenerator, s...)
    y = iterate(dg.iter, s...)
    y === nothing && return nothing
    y = y::Tuple{Any,Any} # try to give inference some idea of what to expect about the behavior of the next line
    return (dg.f(y[1]), y[2])
end
Base.isempty(dg::DiskGenerator) = Base.isempty(dg.iter)
Base.length(dg::DiskGenerator) = Base.length(dg.iter)
Base.ndims(dg::DiskGenerator) = Base.ndims(dg.iter)
Base.size(dg::DiskGenerator) = Base.size(dg.iter)
Base.keys(dg::DiskGenerator) = Base.keys(dg.iter)
function Base.IteratorSize(::Type{DiskGenerator{I,F}}) where {I,F}
    return Base.IteratorSize(Iterators.Generator{I,F})
end
function Base.IteratorEltype(::Type{DiskGenerator{I,F}}) where {I,F}
    return Base.IteratorEltype(Iterators.Generator{I,F})
end

# Collect zipped disk arrays in the right order
# Copied from `collect(::Generator) in julia 1.9
function Base.collect(itr::DiskGenerator{<:AbstractArray{<:Any,N}}) where {N}
    y = iterate(itr)
    shp = axes(itr.iter)
    if y === nothing
        et = Base.@default_eltype(itr)
        return similar(Array{et,N}, shp)
    end
    v1, st = y
    dest = similar(Array{typeof(v1),N}, shp)
    i = y
    for I in eachindex(itr.iter)
        if i isa Nothing # Mainly to keep JET clean 
            error(
                "Should not be reached: iterator is shorter than its `eachindex` iterator"
            )
        else
            dest[I] = first(i)
            i = iterate(itr, last(i))
        end
    end
    return dest
end

# Warning: this is not public API!
function Base.collect_similar(A::AbstractArray, itr::DiskGenerator{<:AbstractArray{<:Any,N}}) where {N}
    y = iterate(itr)
    shp = axes(itr.iter)
    if y === nothing
        et = Base.@default_eltype(itr)
        return similar(A, et, shp)
    end
    v1, st = y
    dest = similar(A, typeof(v1), shp)
    i = y
    for I in eachindex(itr.iter)
        if i isa Nothing # Mainly to keep JET clean 
            error(
                "Should not be reached: iterator is shorter than its `eachindex` iterator"
            )
        else
            dest[I] = first(i)
            i = iterate(itr, last(i))
        end
    end
    return dest

end

macro implement_generator(t)
    t = esc(t)
    quote
        Base.Generator(f, A::$t) = $DiskGenerator(f, A)
    end
end
