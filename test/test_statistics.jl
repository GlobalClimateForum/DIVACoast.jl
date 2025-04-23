# Test Hypsometric Profile
#exit()
using Distributions

# Creates a random Hypsometric Profile
function init_RP()


    x_data = sort(rand(Uniform(4, 6), 10))
    y_data_rp = [1, 2, 5, 10, 25, 50, 100, 250, 500, 1000]
    y_data = map(x -> 1 - 1 / x, y_data_rp)
    y_data[1]=0.0000001
    
    # Define different GEV and GP fits
    gev_gumbel = estimate_gumbel_distribution(x_data, y_data)
    gev_frechet = estimate_frechet_distribution(x_data, y_data)
    gev_weibull = estimate_weibull_distribution(x_data, y_data)
    gpd_exponential = estimate_exponential_distribution(x_data, y_data)
    gpd_positive = estimate_gpd_positive_distribution(x_data, y_data)
    gpd_negative = estimate_gpd_negative_distribution(x_data, y_data)

    #best fit GEV and GP based on minimising error
    gev_best = estimate_gev_distribution(x_data, y_data)
    gpd_best = estimate_gp_distribution(x_data, y_data)

    return x_data, y_data, gev_gumbel, gev_frechet, gev_weibull, gpd_exponential, gpd_positive, gpd_negative, gev_best, gpd_best

end

function runTests()

  x_data, y_data, gev_gumbel, gev_frechet, gev_weibull, gpd_exponential, gpd_positive, gpd_negative, gev_best, gpd_best = init_RP()

    @testset "Distribution fitting" begin
  
      @testset "Best GEV fit" begin
        gumbel_error = gumbel_error_x(x_data, y_data)([gev_gumbel.μ, gev_gumbel.σ, gev_gumbel.ξ])
        frechet_error = frechet_error_x(x_data, y_data)([gev_frechet.μ, gev_frechet.σ, gev_frechet.ξ])
        weibull_error = frechet_error_x(x_data, y_data)([gev_weibull.μ, gev_weibull.σ, gev_weibull.ξ])

        if gumbel_error <= frechet_error && gumbel_error <= weibull_error
          best_fit = gev_gumbel
        elseif frechet_error <= weibull_error
          best_fit = gev_frechet
        else
          best_fit = gev_weibull
        end

        @test best_fit == gev_best[1]
        @test minimum([gumbel_error, frechet_error, weibull_error]) == gev_best[2]
      end

      @testset "Best GP fit" begin
        exponential_error = exponential_error_x(x_data, y_data)([gpd_exponential.μ, gpd_exponential.σ, gpd_exponential.ξ])
        gpd_positive_error = gpd_positive_error_x(x_data, y_data)([gpd_positive.μ, gpd_positive.σ, gpd_positive.ξ])
        gpd_negative_error = gpd_negative_error_x(x_data, y_data)([gpd_negative.μ, gpd_negative.σ, gpd_negative.ξ])

        if exponential_error <= gpd_positive_error && exponential_error <= gpd_negative_error
          best_fit = gpd_exponential
        elseif gpd_positive_error <= gpd_negative_error
          best_fit = gpd_positive
        else
          best_fit = gpd_negative
        end

        @test best_fit == gpd_best[1]
        @test minimum([exponential_error, gpd_positive_error, gpd_negative_error]) == gpd_best[2]
      end
  
    end

    @testset "Linear Interpolation" begin
      d=LinInt(x_data,y_data)

      @test support(d)[4] == x_data[4]
      @test probs(d)[2] == y_data[2]
      @test cdf(d,x_data[7]) == y_data[7]
      @test quantile.(d,0.999) == x_data[end]
    end
end


runTests()


