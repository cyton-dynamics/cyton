using Cyton, Simple

@info "----------------------- start -------------------------"
model = createPopulation(100, cellFactory)
runModel(model, 100.0)
@info "done"
