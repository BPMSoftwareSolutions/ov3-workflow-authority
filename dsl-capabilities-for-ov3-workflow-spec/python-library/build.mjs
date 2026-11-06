import { readFileSync, writeFileSync } from 'node:fs';
import { createHash } from 'node:crypto';
const file = name => new URL(name, import.meta.url);
const read = name => readFileSync(file(name), 'utf8');
const indexUrl = 'https://docs.python.org/3/library/index.html';
const moduleIndexUrl = 'https://docs.python.org/3/py-modindex.html';
const inventory = 'read-python-library-sources';
const proposal = 'propose-python-library-binding';
const sql = (...names) => ({
  dataSource: 'sfx-estate-database', resultColumn: 'value',
  statement: names.map(name=>read(name+'.sql')).join('\n').split(/\r?\n/).map(line => line.trim()).filter(line => line && !line.startsWith('--')).join(' ')
});
const cap = (id, spec) => {
  const featureBytes = readFileSync(file(id + '.feature'));
  const feature = featureBytes.toString('utf8');
  const digest = createHash('sha256').update(featureBytes).digest('hex');
  const step = keyword => feature.match(new RegExp('^    ' + keyword + ' (.+)$', 'm'))[1].trimEnd();
  const outId = feature.match(/^@outcome-contract:(\S+)/m)[1];
  const input = {type:'object', additionalProperties:false, properties:spec.input, ...(spec.required && {required:spec.required})};
  const output = {type:'object', additionalProperties:true, required:['contractId','status'], properties:{contractId:{const:outId}, status:{enum:spec.statuses}, ...spec.output}};
  const lines = [
    'capability ' + id, 'feature ' + id + ' sha256:' + digest, 'intent: ' + spec.intent, 'outcome: ' + spec.outcome,
    ...spec.inquiries.map(x=>'inquiry: '+x),
    'input contract '+id+'-request.v1 '+JSON.stringify(input), 'output contract '+outId+' '+JSON.stringify(output),
    'cli display outcome as json', 'scenario '+id+' root terminal',
    'variants: '+spec.statuses.map((x,i)=>x+(i===0?':success':':failure')).join(','),
    'given: '+step('Given'), 'when: '+step('When'), 'then: '+step('Then')
  ];
  let previous=id;
  const folds=[];
  for(const [op,provider,config,inputs] of spec.operations) {
    const current=id+'.'+op;
    if(config?.forEach) {
      const port=id+'-'+op;
      lines.push('operation '+current+' kind for-each port '+port+' over result.value.'+config.forEach+' max '+config.max);
      folds.push('platform bind '+port,'platform: sda-node-consumer-runtime.v1','config: '+JSON.stringify({
        providerCapabilityId:provider,providerId:provider,authoritySource:'DATABASE',capabilityIdPath:'executionTarget',namespacePath:'executionNamespace',scenarioPath:'executionScenario',requestPath:'dispatchRequest',resultPath:'result',lineageMode:'retain-nested-execution'
      }));
      previous=current;
      continue;
    }
    lines.push('operation '+current+' uses provider '+provider);
    if(config) lines.push('config: '+JSON.stringify(config));
    for(const [member,path] of Object.entries(inputs)) lines.push('input '+member+' from '+previous+' '+path);
    previous=current;
  }
  lines.push('outcome from '+previous+' $.value',...folds,'');
  writeFileSync(file(id+'.dsl'),lines.join('\n'));
};
cap(inventory, {
  intent:'List all Python standard library modules and submodules from the official indexes, including source URLs, descriptions, sections and removal status. For full binding reports, walk nextOffset with expectedIndexHash and send each current module documentationUrl to propose-python-library-binding.',
  outcome:'A sorted inventory page, source digests, population counts and nextOffset, or an explicit source or lookup finding.',
  inquiries:['List all Python libraries and their documentation sources.','Which Python standard library modules can act as providers?','Read the next page of the Python dependency inventory.'],
  statuses:['LISTED','NOT_FOUND','SOURCE_CHANGED','FETCH_FAILED'],
  input:{url:{type:'string',enum:[indexUrl,moduleIndexUrl]},module:{type:'string',minLength:1,maxLength:250},offset:{type:'integer',minimum:0,maximum:100000},limit:{type:'integer',minimum:1,maximum:400},expectedIndexHash:{type:'string',pattern:'^sha256:[0-9a-f]{64}$'}},
  output:{indexedCount:{type:'integer'},removedCount:{type:'integer'},matchingCount:{type:'integer'},nextOffset:{type:'integer'},modules:{type:'array',items:{type:'object',required:['module','removed','section','documentationUrl']}}},
  operations:[
    ['library','http-exchange-public',{method:'GET',url:indexUrl,accept:'text/html'},{context:'$'}],
    ['sections','sql-database-reader',sql('read-sections'),{input:'$'}],
    ['index','http-exchange-public',{method:'GET',url:moduleIndexUrl,accept:'text/html'},{context:'$.value'}],
    ['finish','sql-database-reader',sql('read-modules'),{input:'$'}]
  ]
});
cap(proposal, {
  intent:'Use the web scraper to research one Python standard library module. Propose an estate provider binding with typed input/output contracts, constraints, failure behavior and exactly five ranked use cases. Start larger reports with read-python-library-sources.',
  outcome:'A source-attributed proposed binding and five uses, or an explicit finding. No provider is installed by this capability.',
  inquiries:['What would the provider binding and top five use cases for a Python library look like?','Research a Python module for an estate dependency report.'],
  statuses:['PROPOSED','REMOVED','INSUFFICIENT_SOURCE','MODEL_FAILED','INVALID_PROPOSAL'],
  required:['url'],input:{url:{type:'string',maxLength:1000,pattern:'^https://docs[.]python[.]org/3/library/[A-Za-z0-9_][A-Za-z0-9_.-]*[.]html(#module-[A-Za-z0-9_.]+)?$'}},
  output:{source:{type:'object'},operation:{type:'string'},inputContract:{type:'object'},outputContract:{type:'object'},useCases:{type:'array',minItems:5,maxItems:5,items:{type:'string'}}},
  operations:[
    ['scrape','scrape-web-page',null,{url:'$.url'}],
    ['prompt','sql-database-reader',sql('prepare-proposal'),{input:'$'}],
    ['design','ask-model',null,{modelRequest:'$.value.modelRequest',requestId:'$.value.requestId',requestLineage:'$.value.requestLineage',modelProvider:'$.value.modelProvider',modelRole:'$.value.modelRole'}],
    ['finish','sql-database-reader',sql('validate-proposal'),{input:'$'}]
  ]
});
cap('assemble-python-library-report', {
  intent:'Publish a single Markdown report from the Python module inventory and proposed provider bindings retained in an OV3 conversation. Use this after researching libraries, including partial work. Supply additional named continuation conversations to complete missing modules. Report COMPLETE only when every current module in scope has its own sourced contracts and five ranked uses.',
  outcome:'A retained Markdown report digest, module totals and outstanding count for this scope; an incomplete full inventory is refused before publication.',
  inquiries:['Publish the Python standard library providers report from my research conversation.','Assemble the Python library provider bindings and five use cases into one report.'],
  statuses:['COMPLETE','PARTIAL'],required:['conversationId'],
  input:{conversationId:{type:'string',format:'uuid'},continuations:{type:'array',maxItems:64,items:{type:'string',format:'uuid'}},module:{type:'string',minLength:1,maxLength:250}},
  output:{contentDigest:{type:'string'},scope:{type:'string'},proposals:{type:'integer'},missingCount:{type:'integer'}},
  operations:[
    ['assemble','sql-database-reader',sql('report-coverage','match-proposals','assemble-report'),{input:'$'}],
    ['publish','apply-declared-change',{contractId:'declared-change.v1',changeKind:'content-artifact-change'},{payload:'$.value'}],
    ['finish','sql-database-reader',sql('report-receipt'),{input:'$'}]
  ]
});
cap('research-python-library-batch',{
  intent:'Research up to five official Python library documentation URLs using the proposal capability and retain the structured public results as one reusable batch.',
  outcome:'A retained public research batch digest.',inquiries:['Research this batch of Python module URLs.'],
  statuses:['RETAINED'],required:['sources'],input:{sources:{type:'array',minItems:1,maxItems:5,items:{type:'object',required:['url'],properties:{url:{type:'string',maxLength:900}}}}},output:{contentDigest:{type:'string'}},
  operations:[
    ['plan','sql-database-reader',sql('plan-module-reads'),{input:'$'}],
    ['research',proposal,{forEach:'modules',max:5},{}],
    ['prepare','sql-database-reader',sql('retain-batch'),{input:'$'}],
    ['publish','apply-declared-change',{contractId:'declared-change.v1',changeKind:'content-artifact-change'},{payload:'$.value'}],
    ['finish','sql-database-reader',sql('batch-receipt'),{input:'$'}]
  ]
});
cap('research-missing-python-libraries',{
  intent:'Finish the full Python library binding research without asking to narrow it. Use the conversationId of a retained Python inventory. Reconcile completed work, run pending modules in retained batches and resume after interruption. Then call assemble-python-library-report with the same inventory conversationId to publish and check coverage.',
  outcome:'SETTLED or PARTIAL with batch counts. The report assembler determines module coverage.',
  inquiries:['Research every remaining Python standard library module and retain the work.','Continue the full Python provider report without repeating completed modules.'],
  statuses:['SETTLED','PARTIAL'],required:['conversationId'],input:{conversationId:{type:'string',format:'uuid'},continuations:{type:'array',maxItems:64,items:{type:'string',format:'uuid'}},module:{type:'string',minLength:1,maxLength:250},maxModules:{type:'integer',minimum:1,maximum:400}},output:{batchesReturned:{type:'integer'},batchesRetained:{type:'integer'}},
  operations:[
    ['plan','sql-database-reader',sql('report-coverage','match-proposals','plan-batches'),{input:'$'}],
    ['research','research-python-library-batch',{forEach:'batches',max:80},{}],
    ['finish','sql-database-reader',sql('research-receipt'),{input:'$'}]
  ]
});
cap('generate-python-library-report',{
  intent:'Generate the entire Python standard library provider report from https://docs.python.org/3/library/index.html in one invocation. Use the estate web scraper through the batch proposal capability. List every indexed module, design typed input and output contracts and five ranked use cases for each current module, identify removals, and publish one Markdown artifact. Supply only the reference URL. Reuses public source-linked batches retained in the last 24 hours.',
  outcome:'A Markdown artifact digest with COMPLETE or PARTIAL and exact module coverage, verified against the official inventory at publication.',
  inquiries:['Create the full Python standard library report with provider bindings, input/output contracts and the top five use cases for each library.','Use the web scraper to report on every Python standard library module as a potential estate provider.','Finish the Python standard library provider report from the documentation URL.'],
  statuses:['COMPLETE','PARTIAL'],input:{url:{type:'string',enum:[indexUrl,moduleIndexUrl]}},output:{contentDigest:{type:'string'},proposals:{type:'integer'},missingCount:{type:'integer'}},
  operations:[
    ['inventory',inventory,{limit:400},{}],
    ['plan','sql-database-reader',sql('live-coverage','match-proposals','plan-batches'),{input:'$'}],
    ['research','research-python-library-batch',{forEach:'batches',max:80},{}],
    ['verify-inventory',inventory,{limit:400},{}],
    ['assemble','sql-database-reader',sql('live-coverage','match-proposals','assemble-report'),{input:'$'}],
    ['publish','apply-declared-change',{contractId:'declared-change.v1',changeKind:'content-artifact-change'},{payload:'$.value'}],
    ['finish','sql-database-reader',sql('report-receipt'),{input:'$'}]
  ]
});
