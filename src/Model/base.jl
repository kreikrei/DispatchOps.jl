"""
    baseGraph(khazanah, trayek, moda)
mengubah dataframe khazanah menjadi satu graf tidak berarah.
Graf terdiri dari kumpulan `khazanah` yang terhubung oleh `trayek`.
Atribut biaya tiap trayek dikomputasi menggunakan parameter dari `moda`.
"""
function baseGraph(khazanah::DataFrame, trayek::DataFrame, moda::DataFrame)
    G = MetaGraph{vault}()

    # add all node
    for n in eachrow(khazanah)
        attrib = Dict(
            :coo => (x = n.x, y = n.y), 
            :cap => n.cap
        )
        
        add_node!(G, vault(n.id))
        set_props!(G, vault(n.id), attrib)
    end

    # add all arc
    gdf = groupby(moda, :name)
    for r in eachrow(trayek)
        modakey = gdf.keymap[("$(r.moda)",)]
        a = Arc(vault(r.u), vault(r.v), modakey)
        attrib = Dict(
            :dist => haversine(G[src(a)][:coo], G[tgt(a)][:coo], 6372),
            :transit => gdf.parent.transit[modakey],
            :cjarak => gdf.parent.cjarak[modakey],
            :cpeti => gdf.parent.cpeti[modakey],
            :name => gdf.parent.name[modakey],
            :Q => gdf.parent.Q[modakey]
        )

        add_arc!(G, a)
        set_props!(G, a, attrib)
    end

    return G
end

"""
    baseDigraph(mg)
convert base graph menjadi base digraph.
"""
baseDigraph(mg::MetaGraph{vault}) = MetaDigraph(
    Digraph(Graph(mg)),
    Dict(k => v for (k,v) in mg.nprops), 
    Dict(k => v for (k,v) in mg.aprops)
)

"""
    baseDemand(dfdict, khazanah, periode, pecahan)
extract demands from all place and turn it into a 3-dimension matrix of demand.
"""
function baseDemand(dfdict::Dict, khazanah::Vector,periode::Vector,pecahan::Vector)
    d = AxisArray(zeros(length(khazanah), length(periode), length(pecahan));
        khazanah = khazanah,
        periode = periode,
        pecahan = pecahan
    )

    for k in khazanah
        df = dfdict[k]
        for n in names(df)
            d[k,:,n] = getproperty(df,n)
        end
    end

    return d
end

"""
    baseStock(dfdict, khazanah, pecahan)
extract stock levels from all place and turn it into a 2 dimension matrix of stock.
"""
function baseStock(dfdict::Dict, khazanah::Vector, pecahan::Vector)
    d = AxisArray(zeros(length(khazanah), length(pecahan));
        khazanah = khazanah,
        pecahan = pecahan
    )

    for k in khazanah
        df = dfdict[k]
        for n in names(df)
            d[k,n] = getproperty(df,n) |> first
        end
    end

    return d
end