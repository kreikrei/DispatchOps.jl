noisify_fixed(df, param) = DataFrame(
    id = df.id,
    periode = df.periode,
    pecahan = df.pecahan,
    value = [d + (rand([-1,1]) * param) for d in df.value]
)

noisify_varied(df, percent) = DataFrame(
    id = df.id,
    periode = df.periode,
    pecahan = df.pecahan,
    value = [d + (rand([-1,1]) * ceil(percent * abs(d))) for d in df.value]
)