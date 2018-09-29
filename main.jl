include("body.jl")

function generate2d(infile::IO)
    str = read(infile, String)
    list = map(x->split(x, " "), split(str, "\n"))
    T = Vec2d
    bodies::Vector{Body{T}} = []
    for i in 1:length(list)
        if length(list[i]) < 5 continue end
        elems = map(x->parse(Float64, x), list[i])
        pos = (elems[1], elems[2])
        vel = (elems[3], elems[4])
        mass = elems[5]
        push!(bodies, Body(pos, vel, (0.0, 0.0), mass, i))
    end
    bodies
end

function generate3d(infile::IO)
    str = read(infile, String)
    list = map(x->split(x, " "), split(str, "\n"))
    T = Vec3d
    bodies::Vector{Body{T}} = []
    for i in 1:length(list)
        if length(list[i]) < 7 continue end
        elems = map(x->parse(Float64, x), list[i])
        pos = (elems[1], elems[2], elems[3])
        vel = (elems[4], elems[5], elems[6])
        mass = elems[7]
        push!(bodies, Body(pos, vel, (0.0, 0.0, 0.0), mass, i))
    end
    bodies
end

function cycle(bodies::Vector{Body{T}}, dt::Float64, theta::Float64) where {T}
    tree = Tree{T}((-250.0, -250.0, -250.0), 500.0, Vector{Tree{T}}(), nothing)
    Threads.@threads for i in bodies
        updatePos(i, 0.5dt)
    end
    for i in bodies
        push(tree, i)
    end
    Threads.@threads for i in bodies
        apply(i, tree, theta, 1.0, dt)
    end
    Threads.@threads for i in bodies
        updateVel(i, dt)
    end
    Threads.@threads for i in bodies
        updatePos(i, 0.5dt)
    end
end

function main()
    a = time_ns()
    infilename = ARGS[1]
    outfilename = ARGS[2]
    infile = open(infilename, "r")
    outfile = open(outfilename, "w")
    T = parse(Int, ARGS[3]) == 2 ? Vec2d : Vec3d
    bodies::Vector{Body{T}} = []
    if parse(Int, ARGS[3]) == 2
        bodies = generate2d(infile)
    else
        bodies = generate3d(infile)
    end
    for i in 0:3000
        cycle(bodies, 0.0001, 0.3)
        if i % 30 == 0
            println(i)
            for j in bodies
                show(outfile, j)
                write(outfile, "\n")
            end
            write(outfile, "T -0.8 0.8\nt = ")
            write(outfile, string(i))
            write(outfile, "\n")
            write(outfile, "F\n")
            flush(outfile)
        end
    end
    println((time_ns() - a) / 1000000)
end

println(ARGS)
main()
