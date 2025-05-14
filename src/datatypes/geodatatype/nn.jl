using DataFrames
using CSV
using NearestNeighbors
using Distances

export Neighbour, nearest, nearest_coord, coords_to_wide

"""
This function transforms the longitude and latitude columns of an DataFrame to a Matrix in wide-format required
for Nearest Neighbour matching. 
# Parameter
- df: The input DataFrame containing the longitude and latitude column.
- dtype: The datatype the coordinates should be parsed in.
- lonlatCols: The longitude and latitude columns (default = (:lon, :lat))
# Return
- returns created matrix and DataFrame the matrix is based on (omitted NA values).
"""
function coords_to_wide(df::DataFrame, dtype::Type; 
  lonlatCols::Tuple{Union{String, Symbol}, Union{String, Symbol}} = (:lon, :lat), dropna::Bool = true)

    lon, lat = lonlatCols # get the (optional) symbols for lon, lat colum
  
    # returns type missing when can not parse value else returns parsed value
    function na_parser(value, dtype)

      if !(typeof(value) <: dtype)
        value = tryparse(dtype, value)
      end
      return isnothing(value) ? missing : value
    end
      
    # Parse lon, lat values as Float64 & drop NAs  
    df[!, lon] .= map(val -> na_parser(val, dtype), df[!, lon])
    df[!, lat] .= map(val -> na_parser(val, dtype), df[!, lat])

    # Drop NA rows if dropna is set to true
    df = dropna ? filter(row -> !ismissing(row[lon]) && !ismissing(row[lat]), df) : df
    
    # subset lon, lat column from df
    # df = df[:, [lon, lat]]

    df[!, lon] .= convert(Vector{dtype}, df[!, lon])
    df[!, lat] .= convert(Vector{dtype}, df[!, lat])
    
    # transform dataframe DataFrame to Matrix(nrows x ncols) and transpose it to Matrix(ncols x nrows)
    matrix = transpose(Matrix{dtype}(df[:, [lon, lat]]))

    return matrix, df
end


"""
    function Neighbour(df::DataFrame, dtype::Type; lonlatCols::Tuple{Union{String, Symbol}, Union{String, Symbol}} = (:lon, :lat), dropna::Bool = true)

The Neighbour structure is a efficient way to access a `DataFrame` by coordinates. It therfore transforms the longitude and latitude columns `lonlatCols` of the input DataFrame to a Matrix
in wide-format and creates a BallTree object. The BallTree object is then used to search for nearest neighbours efficiently.

# Arguments
- df: The input DataFrame containing the longitude and latitude column.
- dtype: The datatype the coordinates will be parsed in.
- lonlatCols (optional): The longitude and latitude columns (default = (:lon, :lat))
- dropna (optional): Whether na's should be kept or not (default = true).

# Example
```julia
using DataFrames
using CSV

observations = CSV.File("observations.csv") |> DataFrame # read observations.csv as DataFrame
nObservations = Neighbour(observations, Float64, lonlatCols = (:longitude, :latitude), dropna = true) # create Neighbour object
nearest(nObservations, (37.1100, -12.2877)) # search for nearest neighbour of coordinate (37.1100, -12.2877)) # search for nearest neighbour of coordinate (37.1100, -12.2877) in DataFrame
```
"""
struct Neighbour
  tree::BallTree
  wide::Matrix
  dataframe::DataFrame

  function Neighbour(df::DataFrame, dtype::Type; 
    lonlatCols::Tuple{Union{String, Symbol}, Union{String, Symbol}} = (:lon, :lat), dropna::Bool = true)
    wide, df = coords_to_wide(df, dtype; lonlatCols = lonlatCols, dropna = dropna) 
    dataframe = df
    new(BallTree(wide, Haversine(6371.0)), wide, df)
  end
end

"""
    function nearest(n::Neighbour, coordinate::Tuple)

The nearest function performs a nearest neighbour search on the `Neighbours` Object

# Arguments
- n: The Neighbours Object to search trough.
- coordinate: A coordinate the nearest neighbour relates to.

# Return
Returns a tuple (index, distance, info) containing the of the nearest neighbour in the `Neighbour.tree` object,
the distance to the nearest neighbour and the information of the nearest neighbour in the `Neighbour.dataframe` object.
"""
function nearest(n::Neighbour, coordinate::Tuple)
  lon, lat = coordinate
  idx, dist = knn(n.tree, [lon ; lat], 1)
  info_ = n.dataframe[idx[1], :]
  return (index = idx[1], distance = dist[1], info = info_)
end

"""
Mathches two `DataFrames` by coordinates. The function uses the `nearest` function to find the nearest neighbour in a `Neighbour` object for each coordinate in the input DataFrame.

# Arguments 
- n: The Neighbours Object to search trough.
- df: DataFrame holding the coordinates, the nearest neighbour should relate to.
- dtype: DataType the coordinates will be parsed in.
- lonlatCols: Columns names (string / symbol) of the columns in the input 
  dataframe holding the coordinates.
- dropna: Whether na's should be kept or not (default = true).

# Return
Returns a DataFrame containing the index, distance and information of the nearest neighbour for each coordinate in the input DataFrame.

# Example
```julia
using DataFrames
using CSV

last_observations = CSV.File("last_observations.csv") |> DataFrame # read last_observations.csv as DataFrame
new_observations = CSV.File("new_observations.csv") |> DataFrame # read new_observations.csv as DataFrame

nlastObservations = Neighbour(last_observations, Float64, lonlatCols = (:longitude, :latitude), dropna = true)
observations = nearest(nlastObservations, new_observations, Float64, lonlatCols = (:longitude, :latitude), dropna = true) 
```
"""
function nearest(n::Neighbour, df::DataFrame, dtype::Type ; 
  lonlatCols::Tuple{Union{String, Symbol}, Union{String, Symbol}} = (:lon, :lat), dropna::Bool = true)
  wide, df = coords_to_wide(df, dtype, lonlatCols = lonlatCols, dropna = dropna)
  return knn(n.tree, df_wmatrix, 1)
end

"""
    nearest_coord(n::Neighbour, coordinate::Tuple)
    
The nearest_coord function performs a nearest neighbour search on the `Neighbours` Object and returns the coordinates of the nearest neighbour.

# Arguments
- n: The Neighbours Object to search trough.
- coordinate: A coordinate the nearest neighbour relates Tuple{Float64, Float64} (lon, lat) to.

# Return
Returns a tuple (lonN, latN) containing the coordinates of the nearest neighbour in the `Neighbour.tree` object.

# Example
```julia
using DataFrames
using CSV

observations = CSV.File("observations.csv") |> DataFrame # read observations.csv as DataFrame
nObservations = Neighbour(observations, Float64, lonlatCols = (:longitude, :latitude), dropna = true) # create Neighbour object

nearest = nearest_coord(nObservations, (37.1100, -12.2877)) # search for nearest neighbour coordinate of coordinate (37.1100, -12.2877)
```
"""
function nearest_coord(n::Neighbour, coordinate::Tuple)
  lon, lat = coordinate
  index, distance = knn(n.tree, [lon, lat], 1)
  lonN, latN = n.wide[:, index[1]]
  return (lonN, latN)
end

