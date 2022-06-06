using Cyton, Simple, Gadfly

# Gadfly defaults
Gadfly.set_default_plot_size(10cm, 10cm)
Gadfly.push_theme(Theme(background_color="white"))

@info "----------------------- start -------------------------"
model = createPopulation(1000, cellFactory)
counts = runModel(model, 200.0)

@info "run complete, plotting"

vars = [:total :gen0 :gen1 :gen2 :gen3 :gen4 :gen5 :gen6 :gen7 :gen8 :genOther]
h = plot(counts, x=:time, y=Col.value(vars...), color=Col.index(vars...), Geom.line)
display(h)
# fn = "/some/path/x.png"
# h |> PNG(fn, 15cm, 10cm)
# println("Done at model time=$(modelTime(model))")

@info "done"
