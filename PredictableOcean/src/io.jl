#####
##### NetCDF output with provenance (see the netcdf-output skill)
#####

"""
    settings_block(driver_file)

The text of the `##### Settings` block of a driver script, up to `##### Setup` (or the end).
"""
function settings_block(driver_file::AbstractString)
    lines = readlines(driver_file)
    i = findfirst(l -> startswith(l, "##### Settings"), lines)
    i === nothing && return ""
    j = findnext(l -> startswith(l, "##### Setup"), lines, i + 1)
    j = j === nothing ? length(lines) + 1 : j
    return join(lines[(i + 1):(j - 1)], "\n")
end

function git_info(dir::AbstractString)
    run_git(args) = try
        strip(read(Cmd(`git -C $dir $args`; ignorestatus = true), String))
    catch
        ""
    end
    return (commit = run_git(`rev-parse HEAD`),
            branch = run_git(`rev-parse --abbrev-ref HEAD`),
            dirty = !isempty(run_git(`status --porcelain --untracked-files=no`)))
end

const PROVENANCE_PACKAGES = ("Reactant", "Enzyme", "Oceananigans", "SpeedyWeather", "NumericalEarth",
                             "ConservativeRegridding", "PredictableOcean", "NCDatasets")

function package_versions()
    # read the active Manifest directly (no dependence on which packages are installed)
    manifest = joinpath(dirname(Base.active_project()), "Manifest.toml")
    isfile(manifest) || return "unknown (no Manifest.toml)"
    deps = get(TOML.parsefile(manifest), "deps", Dict())
    v = String[]
    for name in PROVENANCE_PACKAGES
        haskey(deps, name) && push!(v, string(name, "=", get(first(deps[name]), "version", "path")))
    end
    return join(v, ", ")
end

"""
    provenance(; driver = "", settings = "", title = "")

Global attributes recording where a file came from: git commit, branch and dirty flag of the
repository, the driver path and its settings block, Julia and package versions, host and date.
"""
function provenance(; driver::AbstractString = "", settings::AbstractString = "", title::AbstractString = "")
    repo = dirname(dirname(@__DIR__))   # PredictableOcean/src -> repository root
    g = git_info(repo)
    return Dict{String, Any}(
        "Conventions" => "CF-1.10",
        "title" => title,
        "git_commit" => g.commit,
        "git_branch" => g.branch,
        "git_dirty" => string(g.dirty),
        "driver" => driver,
        "settings" => settings,
        "julia_version" => string(VERSION),
        "packages" => package_versions(),
        "host" => gethostname(),
        "arch" => string(Sys.ARCH),
        "created" => string(Dates.now()),
        "history" => string(Dates.now(), ": written by PredictableOcean"),
    )
end

"""
    variable_metadata(m::AbstractPropagator)

NamedTuple keyed like `state_slices(m)`, each entry `(units, long_name, dim)`; `dim` names the
non-time dimension (`nothing` for a scalar time series). Models override this.
"""
variable_metadata(m::AbstractPropagator) =
    map(s -> (units = "1", long_name = "", dim = length(s) == 1 ? nothing : "index"), state_slices(m))

"""
    write_trajectory(path, m, t, X; time_units = "days since 0001-01-01", attributes = Dict())

Write the states `X` (state × time, e.g. from [`trajectory`](@ref)) at times `t` to NetCDF,
one variable per part of `state_slices(m)`. Global `attributes` (e.g. [`provenance`](@ref) and
model parameters) are added to the file.
"""
function write_trajectory(path::AbstractString, m::AbstractPropagator, t::AbstractVector, X::AbstractMatrix;
                          time_units = "days since 0001-01-01 00:00:00", attributes = Dict{String, Any}())
    size(X, 2) == length(t) || throw(DimensionMismatch("X has $(size(X, 2)) columns, t has $(length(t))"))
    slices = state_slices(m)
    meta = variable_metadata(m)
    NCDataset(path, "c") do ds
        for (k, v) in attributes
            ds.attrib[k] = v
        end
        defDim(ds, "time", length(t))
        defVar(ds, "time", Float64.(t), ("time",);
               attrib = Dict("units" => time_units, "calendar" => "noleap", "long_name" => "time"))
        for name in keys(slices)
            s = slices[name]
            md = meta[name]
            if md.dim === nothing
                defVar(ds, String(name), X[first(s), :], ("time",);
                       attrib = Dict("units" => md.units, "long_name" => md.long_name))
            else
                if !haskey(ds.dim, md.dim)
                    defDim(ds, md.dim, length(s))
                    defVar(ds, md.dim, collect(1:length(s)), (md.dim,); attrib = Dict("long_name" => md.dim))
                end
                defVar(ds, String(name), X[s, :], (md.dim, "time");
                       attrib = Dict("units" => md.units, "long_name" => md.long_name))
            end
        end
    end
    return path
end
