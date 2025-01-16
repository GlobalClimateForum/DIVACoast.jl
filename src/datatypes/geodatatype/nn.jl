using DataFrames
using CSV
using NearestNeighbors
using Distances

export Neighbour, nearest, nearest_coord, coords_to_wide

"""
This funciton transforms the longitude and latitude columns of an DataFrame to a Matrix in wide-format required
for Nearest Neighbour matching. 
# Parameter
- df: The input DataFrame containing the longitude and latitude column.
- dtype: The datatype the coordinates should be parsed in.
- lonlatCols: The longitude and latitude columns (default = (:lon, :lat))
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
The Neighbours structure holds and BallTree Object and the created Matrix.
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
The nearest function returns the index of nearest neighbour of an Neighbours Object to an coordinate.
# Parameter
  - n: The Neighbours Object to search trough.
  - coordinate: A coordinate the nearest neighbour relates to.
"""
function nearest(n::Neighbour, coordinate::Tuple)
  lon, lat = coordinate
  idx, dist = knn(n.tree, [lon ; lat], 1)
  info_ = n.dataframe[idx[1], :]
  return (index = idx[1], distance = dist[1], info = info_)
end

"""
The nearest function returns the nearest neighbour of an Neighbours Object to multiple coordinates.
Coordinates can be passed to the fucntion as a DataFrame. 
# Parameter
  - n: The Neighbours Object to search trough.
  - df: DataFrame holding the coordinates, the nearest neighbour should relate to.
  - dtype: DataType the coordinates will be parsed in.
  - lonlatCols: Columns names (string / symbol) of the columns in the input 
  dataframe holding the coordinates. 
  - dropna: Whether na's should be kept or not.
"""
function nearest(n::Neighbour, df::DataFrame, dtype::Type ; 
  lonlatCols::Tuple{Union{String, Symbol}, Union{String, Symbol}} = (:lon, :lat), dropna::Bool = true)
  wide, df = coords_to_wide(df, dtype, lonlatCols = lonlatCols, dropna = dropna)
  return knn(n.tree, df_wmatrix, 1)
end

"""
Does same as nearest() but returns Coordinate of nearest neighbour.
"""
function nearest_coord(n::Neighbour, coordinate::Tuple)
  lon, lat = coordinate
  index, distance = knn(n.tree, [lon, lat], 1)
  lonN, latN = n.wide[:, index[1]]
  return (lonN, latN)
end

