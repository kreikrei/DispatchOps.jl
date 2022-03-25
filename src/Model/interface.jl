"""
    locper
tipe data untuk node dari graf expanded. Terdiri dari khazanah dan periode.
"""
struct locper
    loc::String
    per::Int
end

Base.show(io::IO, lp::locper) = print(io, "⟦i=$(lp.loc),t=$(lp.per)⟧")