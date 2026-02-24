using LinearAlgebra
include("../src/newton.jl")
include("../src/regions_de_confiance.jl")
"""

Approximation d'une solution au problème 

    min f(x), x ∈ Rⁿ, sous la c c(x) = 0,

par l'algorithme du lagrangien augmenté.

# Syntaxe

    x_sol, f_sol, flag, nb_iters, μs, λs = lagrangien_augmente(f, gradf, hessf, c, gradc, hessc, x0; kwargs...)

# Entrées

    - f      : (Function) la ftion à minimiser
    - gradf  : (Function) le gradient de f
    - hessf  : (Function) la hessienne de f
    - c      : (Function) la c à valeur dans R
    - gradc  : (Function) le gradient de c
    - hessc  : (Function) la hessienne de c
    - x0     : (Vector{<:Real}) itéré initial
    - kwargs : les options sous formes d'arguments "keywords"
        • max_iter  : (Integer) le nombre maximal d'iterations (optionnel, par défaut 1000)
        • tol_abs   : (Real) la tolérence absolue (optionnel, par défaut 1e-10)
        • tol_rel   : (Real) la tolérence relative (optionnel, par défaut 1e-8)
        • λ0        : (Real) le multiplicateur de lagrange associé à c initial (optionnel, par défaut 2)
        • μ0        : (Real) le facteur initial de pénalité de la c (optionnel, par défaut 10)
        • τ         : (Real) le facteur d'accroissement de μ (optionnel, par défaut 2)
        • algo_noc  : (String) l'algorithme sans c à utiliser (optionnel, par défaut "rc-gct")
            * "newton"    : pour l'algorithme de Newton
            * "rc-cauchy" : pour les régions de confiance avec pas de Cauchy
            * "rc-gct"    : pour les régions de confiance avec gradient conjugué tronqué

# Sorties

    - x_sol    : (Vector{<:Real}) une approximation de la solution du problème
    - f_sol    : (Real) f(x_sol)
    - flag     : (Integer) indique le critère sur lequel le programme s'est arrêté
        • 0 : convergence
        • 1 : nombre maximal d'itération dépassé
    - nb_iters : (Integer) le nombre d'itérations faites par le programme
    - μs       : (Vector{<:Real}) tableau des valeurs prises par μk au cours de l'exécution
    - λs       : (Vector{<:Real}) tableau des valeurs prises par λk au cours de l'exécution

# Exemple d'appel

    f(x)=100*(x[2]-x[1]^2)^2+(1-x[1])^2
    gradf(x)=[-400*x[1]*(x[2]-x[1]^2)-2*(1-x[1]) ; 200*(x[2]-x[1]^2)]
    hessf(x)=[-400*(x[2]-3*x[1]^2)+2  -400*x[1];-400*x[1]  200]
    c(x) =  x[1]^2 + x[2]^2 - 1.5
    gradc(x) = 2*x
    hessc(x) = [2 0; 0 2]
    x0 = [1; 0]
    x_sol, _ = lagrangien_augmente(f, gradf, hessf, c, gradc, hessc, x0, algo_noc="rc-gct")

"""
function lagrangien_augmente(f::Function, gradf::Function, hessf::Function, 
        c::Function, gradc::Function, hessc::Function, x0::Vector{<:Real}; 
        max_iter::Integer=1000, tol_abs::Real=1e-10, tol_rel::Real=1e-8,
        λ0::Real=2, μ0::Real=10, τ::Real=2, algo_noc::String="rc-gct")

    #
    x_sol = x0
    f_sol = f(x_sol)
    flag  = -1
    nb_iters = 0
    μs = [μ0] # vous pouvez faire μs = vcat(μs, μk) pour concaténer les valeurs
    λs = [λ0]

    b = 0.9
    h = 0.1258925
    a = 0.1
    ε0 = 1/μ0
    η = h/(μ0^a)
    xk = x0
    μ = μ0
    λ = λ0
    ε = ε0

    cond0 = (norm(gradf(xk)) <= tol_abs)
    cond3 = false
    while !(cond0 || cond3)
        g(x) = f(x) + transpose(λ)*c(x) + (μ/2) * norm(c(x))^2
        gradg(x) = gradf(x) + transpose(λ)*gradc(x) + μ*gradc(x)*c(x)
        hessg(x) = hessf(x) + transpose(λ)*hessc(x) + μ*hessc(x)*c(x) + μ*gradc(x)*transpose(gradc(x))
        if algo_noc == "newton"
            (xk,_ ,_ ,_ ,_) = newton(g, gradg, hessg, xk, tol_abs = ε, tol_rel = 0)
        elseif algo_noc == "rc-cauchy"
            (xk,_ ,_ ,_ ,_) = regions_de_confiance(g, gradg, hessg, xk, tol_abs = ε, tol_rel = 0 , algo_pas = "cauchy")
        elseif algo_noc == "rc-gct"
            (xk,_ ,_ ,_ ,_) = regions_de_confiance(g, gradg, hessg, xk, tol_abs = ε, tol_rel = 0)
        else
            print("Algo non existant")
        end

        if norm(c(xk)) <= η
            λ = λ + μ*c(xk)
            ε = ε/μ
            η = η/(μ^b)
        else
            μ = τ*μ
            ε = ε0/μ
            η = h /(μ^a)
        end
        cond01 = (norm(gradf(xk) + transpose(λ)*gradc(xk)) <= max(tol_rel * norm(gradf(x0) + transpose(λ0)*gradc(x0)), tol_abs))
        cond02 = (norm(c(xk)) <= max(tol_rel*norm(c(x0)), tol_abs))
        cond0 = cond01 && cond02
        cond1 = (nb_iters == max_iter)
        μs = vcat(μs, [μ]) # vous pouvez faire μs = vcat(μs, μk) pour concaténer les valeurs
        λs = vcat(λs, [λ])
        nb_iters += 1
    end

    if cond0
        flag = 0
    elseif cond1
        flag = 1
    end
    
    x_sol = xk
    f_sol = f(x_sol)
    return x_sol, f_sol, flag, nb_iters, μs, λs

end
