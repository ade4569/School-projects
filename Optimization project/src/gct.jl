using LinearAlgebra
"""
Approximation de la solution du problème 

    min qₖ(s) = s'gₖ + 1/2 s' Hₖ s, sous la contrainte ‖s‖ ≤ Δₖ

# Syntaxe

    s = gct(g, H, Δ; kwargs...)

# Entrées

    - g : (Vector{<:Real}) le vecteur gₖ
    - H : (Matrix{<:Real}) la matrice Hₖ
    - Δ : (Real) le scalaire Δₖ
    - kwargs  : les options sous formes d'arguments "keywords", c'est-à-dire des arguments nommés
        • max_iter : le nombre maximal d'iterations (optionnel, par défaut 100)
        • tol_abs  : la tolérence absolue (optionnel, par défaut 1e-10)
        • tol_rel  : la tolérence relative (optionnel, par défaut 1e-8)

# Sorties

    - s : (Vector{<:Real}) une approximation de la solution du problème

# Exemple d'appel

    g = [0; 0]
    H = [7 0 ; 0 2]
    Δ = 1
    s = gct(g, H, Δ)

"""

function trinome(a::Real,b::Real,c::Real)
    d = b^2 - 4*a*c
    r1 = (-b - sqrt(d)) / (2*a)
    r2 = (-b + sqrt(d)) / (2*a)
    return r1, r2
end

function q(s::Vector{<:Real},g::Vector{<:Real},H::Matrix{<:Real})
    transpose(g)*s + 0.5*transpose(s)*H*s
end

function gct(g::Vector{<:Real}, H::Matrix{<:Real}, Δ::Real; 
    max_iter::Integer = 100, 
    tol_abs::Real = 1e-10, 
    tol_rel::Real = 1e-8)

    j = 0
    gₖ = g
    sₖ = zeros(length(g))
    pₖ = -g
    while (j <= max_iter && norm(gₖ) > max(tol_rel*norm(g),tol_abs))
        k = transpose(pₖ)*H*pₖ
        if k <= 0
            (r1, r2) = trinome(norm(pₖ)^2, 2*transpose(sₖ)*pₖ, norm(sₖ)^2 - Δ^2)
            q1 = q(sₖ + r1*pₖ, g, H)
            q2 = q(sₖ + r2*pₖ, g, H)
            if q1 < q2
                r = r1
            else
                r = r2
            end
            return sₖ + r*pₖ
        end
        a = transpose(gₖ)*gₖ/k
        if norm(sₖ + a*pₖ) >= Δ
            (r1, r2) = trinome(norm(pₖ)^2, 2*transpose(sₖ)*pₖ, norm(sₖ)^2 - Δ^2)
            if r1 > 0
                r = r1
            else
                r = r2
            end 
            return sₖ + r*pₖ
        end
        sₖ = sₖ + a*pₖ
        gc = gₖ
        gₖ = gₖ + a*H*pₖ
        bₖ = transpose(gₖ)*gₖ/(transpose(gc)*gc)
        pₖ = -gₖ + bₖ*pₖ
        j += 1
    end
    return sₖ
end
