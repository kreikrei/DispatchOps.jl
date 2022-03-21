# Catatan2 kode

buat ngambil dan mindahin data demand jadi matriks:

matriks dibentuk

```julia
A = AxisArray(
    zeros(
        length(idkhazanah),
        nrow(sampledf), 
        ncol(sampledf)
    );
    id=idkhazanah,
    period=1:nrow(sampledf),
    pecahan=names(sampledf)
)
```

terus di directory `"~/.julia/dev/DispatchOps/data/demand"` kita panggil

```julia
for id in idkhazanah
    df = CSV.read("$id.csv", DataFrame)
        for n in names(df)
            A[id,:,n] .= getproperty(df,n)[:]
        end
    end
end
```

kyknya buat nge-cover stok yang kurang mending kita bikin dummy variable di jakarta buat representasi produksi. produksi jgn lupa dibuat per pecahan mata uang
