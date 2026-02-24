using Test
include("../test/fonctions_de_tests.jl")

"""
Tester l'algorithme des régions de confiance avec le pas de Cauchy

# Entrées

   - afficher : (Bool) affichage ou non des résultats de chaque test

# les cas de test (dans l'ordre)

	- fct 1 : x011, x012
	- fct 2 : x021, x022, x023

"""
function tester_rc_cauchy(rc::Function, afficher::Bool)

    println("Affichage des résultats des algorithmes : ", afficher, "\n")

	# La tolérance utilisée dans les tests
	tol_erreur = 1e-2

	# 
	algo_pas = "cauchy"

	# l'ensemble de tests
	Test.@testset "RC et pas de Cauchy " begin

		# cas de test 1
		x_sol, f_sol, flag, nb_iters, _ = rc(fct1, grad_fct1, hess_fct1, pts1.x011, algo_pas=algo_pas)
		if (afficher)
			afficher_resultats("RC et " * algo_pas, "f1", pts1.x011, x_sol, f_sol, flag, nb_iters, sol_exacte_fct1)
		end
		Test.@test x_sol ≈ sol_exacte_fct1 atol=tol_erreur
		Test.@test flag == 2
		Test.@test nb_iters == 33

    end
end