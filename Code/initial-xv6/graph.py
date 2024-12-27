import re
import matplotlib.pyplot as plt
from collections import defaultdict
import matplotlib.colors as mcolors

mappings = """
p0 -> pid 4
p1 -> pid 5
p2 -> pid 6
p3 -> pid 7
p4 -> pid 8
p5 -> pid 9
p6 -> pid 10
p7 -> pid 11
p8 -> pid 12
p9 -> pid 13
"""

# Initialize a dictionary to hold the mappings
pid_mappings = {}
process_data = {}
# Process each line in the mappings data
for line in mappings.strip().split("\n"):
    match = re.match(r"p(\d) -> pid (\d+)", line)
    if match:
        p = int(match.group(1))
        pid = int(match.group(2))
        pid_mappings[p] = pid

# invert the mappings
pid_mappings = {v: k for k, v in pid_mappings.items()}


# Sample log data
log_data = """
pid: 4, q: 0, ticks: 211
pid: 5, q: 0, ticks: 211
pid: 6, q: 0, ticks: 211
pid: 7, q: 0, ticks: 211
pid: 8, q: 0, ticks: 211
pid: 9, q: 0, ticks: 211
pid: 10, q: 0, ticks: 212
pid: 11, q: 0, ticks: 213
pid: 12, q: 0, ticks: 214
pid: 13, q: 0, ticks: 215
pid: 4, q: 0, ticks: 216
pid: 5, q: 0, ticks: 216
pid: 6, q: 0, ticks: 216
pid: 7, q: 0, ticks: 216
pid: 8, q: 0, ticks: 216
pid: 9, q: 1, ticks: 216
pid: 10, q: 1, ticks: 217
pid: 11, q: 1, ticks: 218
pid: 12, q: 1, ticks: 219
pid: 13, q: 1, ticks: 220
pid: 9, q: 2, ticks: 221
pid: 10, q: 2, ticks: 222
pid: 11, q: 2, ticks: 223
pid: 12, q: 2, ticks: 224
pid: 13, q: 2, ticks: 225
pid: 9, q: 2, ticks: 226
pid: 10, q: 2, ticks: 227
pid: 11, q: 2, ticks: 228
pid: 12, q: 2, ticks: 229
pid: 13, q: 2, ticks: 230
pid: 9, q: 2, ticks: 231
pid: 10, q: 2, ticks: 232
pid: 11, q: 2, ticks: 233
pid: 12, q: 2, ticks: 234
pid: 13, q: 2, ticks: 235
pid: 9, q: 2, ticks: 236
pid: 10, q: 2, ticks: 237
pid: 11, q: 2, ticks: 238
pid: 12, q: 2, ticks: 239
pid: 13, q: 2, ticks: 240
pid: 9, q: 2, ticks: 241
pid: 10, q: 2, ticks: 242
pid: 11, q: 2, ticks: 243
pid: 12, q: 2, ticks: 244
pid: 13, q: 2, ticks: 245
pid: 9, q: 2, ticks: 246
pid: 10, q: 2, ticks: 247
pid: 11, q: 2, ticks: 248
pid: 12, q: 2, ticks: 249
pid: 13, q: 2, ticks: 250
pid: 9, q: 2, ticks: 251
pid: 10, q: 2, ticks: 252
pid: 11, q: 2, ticks: 253
pid: 12, q: 2, ticks: 254
pid: 13, q: 2, ticks: 255
pid: 9, q: 2, ticks: 256
pid: 10, q: 2, ticks: 257
pid: 11, q: 2, ticks: 258
pid: 12, q: 2, ticks: 259
pid: 13, q: 2, ticks: 260
pid: 9, q: 2, ticks: 261
pid: 10, q: 2, ticks: 262
pid: 11, q: 2, ticks: 263
pid: 12, q: 2, ticks: 264
pid: 13, q: 2, ticks: 265
pid: 9, q: 2, ticks: 266
pid: 10, q: 2, ticks: 267
pid: 11, q: 2, ticks: 268
pid: 12, q: 2, ticks: 269
pid: 13, q: 2, ticks: 270
pid: 9, q: 2, ticks: 271
pid: 10, q: 2, ticks: 272
pid: 11, q: 2, ticks: 273
pid: 12, q: 2, ticks: 274
pid: 13, q: 2, ticks: 275
pid: 9, q: 2, ticks: 276
pid: 10, q: 2, ticks: 277
pid: 11, q: 2, ticks: 278
pid: 12, q: 2, ticks: 279
pid: 13, q: 2, ticks: 280
pid: 9, q: 2, ticks: 281
pid: 10, q: 2, ticks: 282
pid: 11, q: 2, ticks: 283
pid: 12, q: 2, ticks: 284
pid: 13, q: 2, ticks: 285
pid: 9, q: 2, ticks: 286
pid: 10, q: 2, ticks: 287
pid: 11, q: 2, ticks: 288
pid: 12, q: 2, ticks: 289
pid: 13, q: 2, ticks: 290
pid: 9, q: 2, ticks: 291
pid: 10, q: 2, ticks: 292
pid: 11, q: 2, ticks: 293
pid: 12, q: 2, ticks: 294
pid: 13, q: 2, ticks: 295
pid: 9, q: 2, ticks: 296
pid: 10, q: 2, ticks: 297
pid: 11, q: 2, ticks: 298
pid: 12, q: 2, ticks: 299
pid: 13, q: 2, ticks: 300
pid: 9, q: 2, ticks: 301
pid: 10, q: 2, ticks: 302
pid: 11, q: 2, ticks: 303
pid: 12, q: 2, ticks: 304
pid: 13, q: 2, ticks: 305
pid: 9, q: 2, ticks: 306
pid: 10, q: 2, ticks: 307
pid: 11, q: 2, ticks: 308
pid: 12, q: 2, ticks: 309
pid: 13, q: 2, ticks: 310
pid: 9, q: 2, ticks: 311
pid: 10, q: 2, ticks: 312
pid: 11, q: 2, ticks: 313
pid: 12, q: 2, ticks: 314
pid: 13, q: 2, ticks: 315
pid: 9, q: 2, ticks: 316
pid: 10, q: 2, ticks: 317
pid: 11, q: 2, ticks: 318
pid: 12, q: 2, ticks: 319
pid: 13, q: 2, ticks: 320
pid: 9, q: 2, ticks: 321
pid: 10, q: 2, ticks: 322
pid: 11, q: 2, ticks: 323
pid: 12, q: 2, ticks: 324
pid: 13, q: 2, ticks: 325
pid: 9, q: 2, ticks: 326
pid: 10, q: 2, ticks: 327
pid: 11, q: 2, ticks: 328
pid: 12, q: 2, ticks: 329
pid: 13, q: 2, ticks: 330
pid: 9, q: 2, ticks: 331
pid: 10, q: 2, ticks: 332
pid: 11, q: 2, ticks: 333
pid: 12, q: 2, ticks: 334
pid: 13, q: 2, ticks: 335
pid: 9, q: 2, ticks: 336
pid: 10, q: 2, ticks: 337
pid: 11, q: 2, ticks: 338
pid: 12, q: 2, ticks: 339
pid: 13, q: 2, ticks: 340
pid: 9, q: 2, ticks: 341
pid: 10, q: 2, ticks: 342
pid: 11, q: 2, ticks: 343
pid: 12, q: 2, ticks: 344
pid: 13, q: 2, ticks: 345
pid: 9, q: 2, ticks: 346
pid: 10, q: 2, ticks: 347
pid: 11, q: 2, ticks: 348
pid: 12, q: 2, ticks: 349
pid: 13, q: 2, ticks: 350
pid: 9, q: 2, ticks: 351
pid: 10, q: 2, ticks: 352
pid: 11, q: 2, ticks: 353
pid: 12, q: 2, ticks: 354
pid: 13, q: 2, ticks: 355
pid: 9, q: 2, ticks: 356
pid: 10, q: 2, ticks: 357
pid: 11, q: 2, ticks: 358
pid: 12, q: 2, ticks: 359
pid: 13, q: 2, ticks: 360
pid: 9, q: 2, ticks: 361
pid: 10, q: 2, ticks: 362
pid: 11, q: 2, ticks: 363
pid: 12, q: 2, ticks: 364
pid: 13, q: 2, ticks: 365
pid: 9, q: 2, ticks: 366
pid: 10, q: 2, ticks: 367
pid: 11, q: 2, ticks: 368
pid: 12, q: 2, ticks: 369
pid: 13, q: 2, ticks: 370
pid: 9, q: 2, ticks: 371
pid: 10, q: 2, ticks: 372
pid: 11, q: 2, ticks: 373
pid: 12, q: 2, ticks: 374
pid: 13, q: 2, ticks: 375
pid: 9, q: 2, ticks: 376
pid: 10, q: 2, ticks: 377
pid: 11, q: 2, ticks: 377
pid: 12, q: 2, ticks: 378
pid: 13, q: 2, ticks: 379
pid: 9, q: 2, ticks: 380
pid: 11, q: 2, ticks: 381
pid: 12, q: 2, ticks: 382
pid: 13, q: 2, ticks: 382
pid: 9, q: 2, ticks: 382
pid: 11, q: 2, ticks: 382
pid: 4, q: 0, ticks: 382
pid: 5, q: 0, ticks: 382
pid: 6, q: 0, ticks: 382
pid: 7, q: 0, ticks: 382
pid: 8, q: 0, ticks: 382
pid: 3, q: 0, ticks: 382
pid: 4, q: 0, ticks: 383
pid: 5, q: 0, ticks: 383
pid: 6, q: 0, ticks: 383
pid: 7, q: 0, ticks: 383
pid: 8, q: 0, ticks: 383
pid: 4, q: 0, ticks: 384
pid: 5, q: 0, ticks: 384
pid: 6, q: 0, ticks: 384
pid: 7, q: 0, ticks: 384
pid: 8, q: 0, ticks: 384
pid: 4, q: 0, ticks: 385
pid: 5, q: 0, ticks: 385
pid: 6, q: 0, ticks: 385
pid: 7, q: 0, ticks: 385
pid: 8, q: 0, ticks: 385
pid: 4, q: 0, ticks: 386
pid: 5, q: 0, ticks: 386
pid: 6, q: 0, ticks: 386
pid: 7, q: 0, ticks: 386
pid: 8, q: 0, ticks: 386
pid: 4, q: 0, ticks: 387
pid: 5, q: 0, ticks: 387
pid: 6, q: 0, ticks: 387
pid: 7, q: 0, ticks: 387
pid: 8, q: 0, ticks: 387
pid: 4, q: 0, ticks: 388
pid: 5, q: 0, ticks: 388
pid: 6, q: 0, ticks: 388
pid: 7, q: 0, ticks: 388
pid: 8, q: 0, ticks: 388
pid: 4, q: 0, ticks: 389
pid: 5, q: 0, ticks: 389
pid: 6, q: 0, ticks: 389
pid: 7, q: 0, ticks: 389
pid: 8, q: 0, ticks: 389
pid: 4, q: 0, ticks: 390
pid: 5, q: 0, ticks: 390
pid: 6, q: 0, ticks: 390
pid: 7, q: 0, ticks: 390
pid: 8, q: 0, ticks: 390
pid: 4, q: 0, ticks: 391
pid: 5, q: 0, ticks: 391
pid: 6, q: 0, ticks: 391
pid: 7, q: 0, ticks: 391
pid: 8, q: 0, ticks: 391
pid: 4, q: 0, ticks: 392
pid: 5, q: 0, ticks: 392
pid: 6, q: 0, ticks: 392
pid: 7, q: 0, ticks: 392
pid: 8, q: 0, ticks: 392
pid: 4, q: 0, ticks: 393
pid: 5, q: 0, ticks: 393
pid: 6, q: 0, ticks: 393
pid: 7, q: 0, ticks: 393
pid: 8, q: 0, ticks: 393
pid: 4, q: 0, ticks: 394
pid: 5, q: 0, ticks: 394
pid: 6, q: 0, ticks: 394
pid: 7, q: 0, ticks: 394
pid: 8, q: 0, ticks: 394
pid: 4, q: 0, ticks: 395
pid: 5, q: 0, ticks: 395
pid: 6, q: 0, ticks: 395
pid: 7, q: 0, ticks: 395
pid: 8, q: 0, ticks: 395
pid: 4, q: 0, ticks: 396
pid: 5, q: 0, ticks: 396
pid: 6, q: 0, ticks: 396
pid: 7, q: 0, ticks: 396
pid: 8, q: 0, ticks: 396
pid: 4, q: 0, ticks: 397
pid: 5, q: 0, ticks: 397
pid: 6, q: 0, ticks: 397
pid: 7, q: 0, ticks: 397
pid: 8, q: 0, ticks: 397
pid: 4, q: 0, ticks: 398
pid: 5, q: 0, ticks: 398
pid: 6, q: 0, ticks: 398
pid: 7, q: 0, ticks: 398
pid: 8, q: 0, ticks: 398
pid: 4, q: 0, ticks: 399
pid: 5, q: 0, ticks: 399
pid: 6, q: 0, ticks: 399
pid: 7, q: 0, ticks: 399
pid: 8, q: 0, ticks: 399
pid: 4, q: 0, ticks: 400
pid: 5, q: 0, ticks: 400
pid: 6, q: 0, ticks: 400
pid: 7, q: 0, ticks: 400
pid: 8, q: 0, ticks: 400
pid: 4, q: 0, ticks: 401
pid: 5, q: 0, ticks: 401
pid: 6, q: 0, ticks: 401
pid: 7, q: 0, ticks: 401
pid: 8, q: 0, ticks: 401
pid: 4, q: 0, ticks: 402
pid: 5, q: 0, ticks: 402
pid: 6, q: 0, ticks: 402
pid: 7, q: 0, ticks: 402
pid: 8, q: 0, ticks: 402
pid: 4, q: 0, ticks: 403
pid: 5, q: 0, ticks: 403
pid: 6, q: 0, ticks: 403
pid: 7, q: 0, ticks: 403
pid: 8, q: 0, ticks: 403
pid: 4, q: 0, ticks: 404
pid: 5, q: 0, ticks: 404
pid: 6, q: 0, ticks: 404
pid: 7, q: 0, ticks: 404
pid: 8, q: 0, ticks: 404
pid: 4, q: 0, ticks: 405
pid: 5, q: 0, ticks: 405
pid: 6, q: 0, ticks: 405
pid: 7, q: 0, ticks: 405
pid: 8, q: 0, ticks: 405
pid: 4, q: 0, ticks: 406
pid: 5, q: 0, ticks: 406
pid: 6, q: 0, ticks: 406
pid: 7, q: 0, ticks: 406
pid: 8, q: 0, ticks: 406
pid: 4, q: 0, ticks: 407
pid: 5, q: 0, ticks: 407
pid: 6, q: 0, ticks: 407
pid: 7, q: 0, ticks: 407
pid: 8, q: 0, ticks: 407
pid: 4, q: 0, ticks: 408
pid: 5, q: 0, ticks: 408
pid: 6, q: 0, ticks: 408
pid: 7, q: 0, ticks: 408
pid: 8, q: 0, ticks: 408
pid: 4, q: 0, ticks: 409
pid: 5, q: 0, ticks: 409
pid: 6, q: 0, ticks: 409
pid: 7, q: 0, ticks: 409
pid: 8, q: 0, ticks: 409
pid: 4, q: 0, ticks: 410
pid: 5, q: 0, ticks: 410
pid: 6, q: 0, ticks: 410
pid: 7, q: 0, ticks: 410
pid: 8, q: 0, ticks: 410
pid: 4, q: 0, ticks: 411
pid: 5, q: 0, ticks: 411
pid: 6, q: 0, ticks: 411
pid: 7, q: 0, ticks: 411
pid: 8, q: 0, ticks: 411
pid: 3, q: 0, ticks: 411
Average rtime 17, wtime 167
pid: 2, q: 2, ticks: 411
"""

# initialize a dictionary to the priority of each process at each tick
priority_data = defaultdict(list)

# Process each line in the log data
for line in log_data.strip().split("\n"):
    match = re.match(r"pid: (\d+), q: (\d+), ticks: (\d+)", line)
    if match:
        pid = int(match.group(1))
        q = int(match.group(2))
        ticks = int(match.group(3))
        # Get the mapped pid
        pid = pid_mappings.get(pid, pid)
        # Add the priority to the dictionary
        priority_data[ticks].append((pid, q))

# replace the pid with the mapped pid from process mappings
# for tick, entries in priority_data.items():
#     updated_entries = []
#     for pid, q in entries:
#         updated_entries.append((pid_mappings.get(pid, pid), q))
#     priority_data[tick] = updated_entries


# plotting a time line graph
# Uncomment the following line if you want to see the priority data
# print(priority_data)

# ------------------- Plotting Section -------------------

# Collect per-pid tick and q data
process_data = defaultdict(list)

for tick, entries in priority_data.items():
    for pid, q in entries:
        process_data[pid].append((tick, q))


# Sort the tick data for each process
for pid in process_data:
    process_data[pid].sort()

# Assign a unique color to each process
colors = list(mcolors.TABLEAU_COLORS.values())
color_map = {}
for i, pid in enumerate(sorted(process_data.keys())):
    color_map[pid] = colors[i % len(colors)]

# Create the plot
plt.figure(figsize=(14, 8))

for pid, data in process_data.items():
    ticks, qs = zip(*data)
    plt.plot(ticks, qs, label=f"PID {pid}", color=color_map[pid], linewidth=2)

plt.xlabel("Ticks", fontsize=14)
plt.ylabel("Queue ID", fontsize=14)
plt.title("Process Queue Positions Over Time", fontsize=16)
plt.legend(title="Processes", fontsize=12, title_fontsize=12)
plt.gca()  # Higher queue IDs represent lower priorities
plt.grid(True, linestyle="--", alpha=0.5)
plt.tight_layout()
plt.show()
