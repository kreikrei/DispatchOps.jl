"""
    vault
tipe data untuk node dari graf dasar yg berupa khazanah.
"""
struct vault
    name::String
end

"""
    locper
tipe data untuk node dari graf expanded. Terdiri dari khazanah dan periode.
"""
struct locper
    loc::vault
    per::Int
end

Base.show(io::IO, v::vault) = print(io,"$(v.name)")
Base.show(io::IO, lp::locper) = print(io, "⟦i=$(lp.loc),t=$(lp.per)⟧")