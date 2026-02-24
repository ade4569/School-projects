# Ecrire les tests de l'algorithme du pas de Cauchy
using Test
using LinearAlgebra

function tester_cauchy(cauchy::Function)

    g1 = [0, 1]
    H1 = [1 1;1 1]
    Δ1 = 1.0
    g2 = [2, 2]
    H2 = [2 0;0 2]
    Δ2 = 0.01
    g3 = [2, 2]
    H3 = [0 0;0 0]
    Δ3 = 1.0
    g4 = [2, 2]
    H4 = [-2 0;0 -2]
    Δ4 = 1.0

	Test.@testset "Pas de Cauchy" begin
        Test.@testset "a > 0 minimum dedans" begin
            s = cauchy(g1, H1, Δ1)
            Test.@testset "solution" begin
                Test.@test s == [0.0, -1.0]
            end
        end
        Test.@testset "a > 0 minimum dehors" begin
            s = cauchy(g2, H2, Δ2)
            Test.@testset "solution" begin
                Test.@test s == [-0.02/sqrt(8), -0.02/sqrt(8)]
            end
        end
        Test.@testset "a = 0" begin
            s = cauchy(g3, H3, Δ3)
            Test.@testset "solution" begin
                Test.@test s == [-2/sqrt(8), -2/sqrt(8)]
            end
        end
        Test.@testset "a < 0" begin
            s = cauchy(g4, H4, Δ4)
            Test.@testset "solution" begin
                Test.@test s == [-2/sqrt(8), -2/sqrt(8)]
            end
        end
    end

end