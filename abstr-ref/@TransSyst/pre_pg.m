function [W, cont] = pre_pg(ts, V, B, quant1)
  % pre_pg: pre(V) under (quant1, forall) while remaining in B using progress groups
  % 
  % Returns a sorted set
  W = uint32(V);
  Vlist = {V};
  Klist = {Controller(W, containers.Map(), 'simple')};
  for i=1:length(ts.pg_U)
    % Progress groups
    if nargout > 1
      [preVinv, preKinv] = ts.pginv(ts.pg_U{i}, ts.pg_G{i}, W, B, quant1);
      if length(preVinv) > 0
        Vlist{end+1} = preVinv;
        Klist{end+1} = preKinv;
      end
    else
      preVinv = ts.pginv(ts.pg_U{i}, ts.pg_G{i}, W, B, quant1);
    end
    W = union(W, preVinv);
    W = reshape(W, 1, length(W));
  end

  if nargout > 1
    cont = Controller(Vlist, Klist, 'reach', 'pre_pg');
  end
end