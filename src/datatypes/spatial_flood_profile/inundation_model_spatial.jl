struct HydraulicConnectedBathtub <: InundationModel
    function HydraulicConnectedBathtub()
        return new()
    end
end

struct PathBasedAttenuatedBathtub <: InundationModel
    attrate::Union{Real, AbstractArray{Real, 2}}
    function PathBasedAttenuatedBathtub(attrate::Union{Real, AbstractArray{Real, 2}})
        return new(attrate)
    end
end 