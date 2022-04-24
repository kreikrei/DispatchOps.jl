
# NETWORK STRUCTURE
D = sim.acc.executed_dispatch

filename = "uniquetrayek_test"
open("./out/$filename.dot", "w") do file
    write(file, "digraph $filename {\n")
    write(file, "    splines=polyline\n")
    write(file, "    overlap=false\n")

    for r in eachrow(libs.khazanah)
        y = 6372 * 0.9982 * r.y
        x = 6372 * 0.9982 * r.x

        write(file, "    $(r.id) [\n")
        write(file, "        pos = \"$(x),$(y)!\"\n")
        write(file, "    ];\n")
    end

    for a in arcs(D)
        i = src(a).loc
        j = tgt(a).loc
        write(file, "    $i -> $j [label = \"$(D[a][:moda])\"];\n")
    end

    write(file, "}")
end

testIO = open("./out/$filename.dot")
GraphViz.load(testIO)