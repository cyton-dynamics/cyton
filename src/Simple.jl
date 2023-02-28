module Simple

export cellFactory, runModel
"""
A simple cell has the following behaviour
- It does not divide prior to stimulation
- After stimulation there is a delay to first division
- After first division the cell will divide until it reaches destiny
- Most cells will die after a period of time.
- A proportion of cells will not die - memory cells
  - memory cell fate occurs at constant (slow) rate
  - memory cells don't divide

In this simple, proof of concept model:
- all lifetimes are drawn from LogNormalParms
- Time to next division are initiated de novo on creation/division
- Time to die is inherited

Time units are hours.
"""

using Cyton
import Cyton: sample, inherit, step

using DataFrames


# Parameters from the Cyton2 paper
λ_firstDivision = LogNormalParms(log(39.89), 0.28)
λ_subsequentDivision = FixedDistributionParms(9.21)
λ_divisionDestiny = LogNormalParms(log(71.86), 0.11)
λ_lifetime = LogNormalParms(log(116.8), 0.85)

@enum Fate Undivided Dividing Destiny


"""
Time to die is drawn from a distribution when the cell is created.
Daughter cells will inherit this. It is nulled if the cell becomes
a memory cell.
"""
struct DeathTimer <: FateTimer
  timeToDeath::Time
end
function DeathTimer(r::DistributionParmSet)
  DeathTimer(sample(r))
end
inherit(timer::DeathTimer, ::Time) = timer
function step(death::DeathTimer, time::Time, Δt::Duration)::Union{CellEvent, Nothing}
  if time > death.timeToDeath
    return Death()
  else
    return nothing
  end
end

"Time to divide drawn from distribution"
struct DivisionTimer <: FateTimer
  timeToDivision::Time
  timeToDestiny::Time
end
"Constructor for fresh cells"
DivisionTimer(division::DistributionParmSet, destiny::DistributionParmSet) = DivisionTimer(sample(division), sample(destiny))
"Constructor for daughter cells"
DivisionTimer(r::DistributionParmSet, start::Time, destiny::Time) = DivisionTimer(sample(r) + start, destiny)

function step(division::DivisionTimer, time::Time, Δt::Duration) 
  if time < division.timeToDestiny && time > division.timeToDivision
    return Division()
  else
    return nothing
  end
end
inherit(timer::DivisionTimer, time::Time) = DivisionTimer(λ_subsequentDivision, time, timer.timeToDestiny)

"Create a new cell"
function cellFactory(birth::Time=0.0)
  cell = Cell(birth)
  addTimer(cell, DeathTimer(λ_lifetime))
  addTimer(cell, DivisionTimer(λ_firstDivision, λ_divisionDestiny))
  return cell
end

function runModel(model::CytonModel, runDuration::Time)
  print("Time to run:")
  @time begin
    counts = DataFrame(time=Time[], 
    total=[], 
    gen0 = [],
    gen1 = [],
    gen2 = [],
    gen3 = [],
    gen4 = [],
    gen5 = [],
    gen6 = [],
    gen7 = [],
    gen8 = [],
    genOther = []
    )
    Δt = modelTimeStep(model)
    for tm in 1:Δt:runDuration
      step(model)

      local genCnts = zeros(10)
      cells = keys(model.cells)
      for cell in cells
        gen = cell.generation
        if gen <= 8
          genCnts[gen+1] += 1
        else
          genCnts[10] += 1
        end
      end
      push!(counts, (tm, length(cells), genCnts...))
    end
  end

  return counts
end


end # module Simple
