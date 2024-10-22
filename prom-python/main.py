from fastapi import FastAPI, Request                    
from fastapi.middleware.cors import CORSMiddleware      
from prometheus_client import make_asgi_app, Gauge             
import time, math, asyncio, random

app = FastAPI(debug=False)
origins = ["*"]
app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

BILLED_API_COUNTER = Gauge(
    'billed_api_counter', 
    'Count of Customer HTTP requests made to my API',
    ['customer'])


BILLED_API_DURATION = Gauge(
    'billed_api_duration',
    'Amount of time consumed by Customer HTTP requests made to my API', 
    ['customer']
)


metrics_app = make_asgi_app()
app.mount("/metrics", metrics_app)

@app.middleware('http')
async def some_middleware(request: Request, call_next):
    start_time = time.time()
    # Get customer        
    
    response = await call_next(request)
    
    headers = dict(request.scope['headers'])    
    
    if b'customer' in headers: 
        customerHeader  = headers[b'customer'].decode("utf-8")        
        duration = math.ceil((time.time() - start_time) * 1000)
        print(f"Customer: {customerHeader}. Time taken(ms) to process {str(request.url)} is: {duration}")
        BILLED_API_COUNTER.labels(customer=customerHeader).inc()
        BILLED_API_DURATION.labels(customer=customerHeader).inc(duration)

    return response

# Sleep function: Simulates a delay of up to `s` seconds with random time.
async def sleep(s: int):
    delay = random.uniform(0, s)  # Random delay between 0 and s seconds
    await asyncio.sleep(delay)

@app.get("/operation1")
async def get_operation1():
    print("This operation will take a random time up to 1 second to complete")
    await sleep(1)  
    return "OK[op1]"


@app.get("/operation2")
async def get_operation2():
    print("This operation will take a random time up to 10 seconds to complete")
    await sleep(10) 
    return "OK[op2]"

@app.get("/reset")
async def get_reset():
    BILLED_API_COUNTER._metrics.clear()
    BILLED_API_DURATION._metrics.clear()
    return "OK[reset]"
