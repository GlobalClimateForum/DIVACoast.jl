include("exercies1_functions_implemented.jl")

# Test if path, given as an array of pairs, is a valid path from startcell to endcell ind dataset 
function valid_4connected_path(dataset :: Array{Float64}, path :: Array{Tuple{Int64,Int64}}, startcell :: Tuple{Int64,Int64}, endcell :: Tuple{Int64,Int64}) :: Bool 
  if (path[1] != startcell) return false end
  if (path[size(path,1)] != endcell) return false end
  if dataset[path[1][1],path[1][2]]==-Inf return false end

  for i in 2:size(path,1)
    if dataset[path[i][1],path[i][2]]==-Inf return false end
    if !(path[i] in nh4(dataset,path[i-1])) return false end
  end
  return true
end

function valid_8connected_path(dataset :: Array{Float64}, path :: Array{Tuple{Int64,Int64}}, startcell :: Tuple{Int64,Int64}, endcell :: Tuple{Int64,Int64}) :: Bool 
  if (path[1] != startcell) return false end
  if (path[size(path,1)] != endcell) return false end
  if dataset[path[1][1],path[1][2]]==-Inf return false end

  for i in 2:size(path,1)
    if dataset[path[i][1],path[i][2]]==-Inf return false end
    if !(path[i] in nh8(dataset,path[i-1])) return false end
  end
  return true
end

# 
function coastline(dataset  :: Array{Float64}) :: Array{Bool}
  cl  :: Array{Bool} = Array{Bool}(undef, size(dataset,1), size(dataset,2))
  for i in 1:size(dataset,1)
    for j in 1:size(dataset,2)
      if (dataset[i,j]!=-Inf) 
        for nhc in nh8(dataset, i, j) 
	  if dataset[nhc[1],nhc[2]]==-Inf cl[i,j]=true end
        end
      end
    end
  end
  return cl
end

